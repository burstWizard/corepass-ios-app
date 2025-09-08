import SwiftUI
import FirebaseFirestore

// Map PassStatus -> your UI ApprovalStatus
private extension ApprovalStatus {
    init(from status: PassStatus) {
        switch status {
        case .pending:  self = .pending
        case .approved: self = .approved
        case .rejected: self = .rejected
        }
    }
}

// MARK: - Service (protocol + default Firestore impl)

protocol PassesServiceProtocol {
    func startListening(for uid: String, onChange: @escaping ([Pass]) -> Void)
    func stopListening()
    func endPass(id: String) async throws
}

final class FirestorePassesService: PassesServiceProtocol {
    private var listener: ListenerRegistration?

    func startListening(for uid: String, onChange: @escaping ([Pass]) -> Void) {
        listener?.remove()
        listener = Firestore.firestore()
            .collection("passes")
            .whereField("author", isEqualTo: uid)
            .order(by: "created_at", descending: true)
            .addSnapshotListener { snap, _ in
                let items: [Pass] = snap?.documents.compactMap { try? $0.data(as: Pass.self) } ?? []
                onChange(items)
            }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }

    func endPass(id: String) async throws {
        try await Firestore.firestore()
            .collection("passes")
            .document(id)
            .updateData(["active": false])
    }
}

// MARK: - ViewModel

@MainActor
final class MyPassesViewModel: ObservableObject {
    @Published var activePass: Pass?
    @Published var requested: [Pass] = []
    @Published var past: [Pass] = []
    @Published var error: String?
    @Published var isLoading = true

    private let service: PassesServiceProtocol

    init(service: PassesServiceProtocol = FirestorePassesService()) {
        self.service = service
    }

    func start() {
        stop() // in case
        guard let uid = Services.session.uid else {
            self.error = "Not signed in."
            self.isLoading = false
            return
        }
        isLoading = true

        service.startListening(for: uid) { [weak self] all in
            guard let self else { return }
            let buckets = Self.bucket(all)
            self.activePass = buckets.active
            self.requested  = buckets.requested
            self.past       = buckets.past
            self.error = nil
            self.isLoading = false
        }
    }

    func stop() {
        service.stopListening()
    }

    func end(_ pass: Pass) async {
        guard let id = pass.id else {
            self.error = "Missing pass id."
            return
        }
        do {
            try await service.endPass(id: id)
            // listener will refresh
        } catch {
            self.error = error.localizedDescription
        }
    }

    /// Pure bucketing logic (unit-testable).
    static func bucket(_ all: [Pass]) -> (active: Pass?, requested: [Pass], past: [Pass]) {
        // Active: active == true (most recent by createdAt if multiple)
        let active = all
            .filter { $0.active }
            .sorted { $0.createdAt > $1.createdAt }
            .first

        // Requested: pending AND not active
        let requested = all
            .filter { $0.approved == .pending && !$0.active }
            .sorted { $0.createdAt > $1.createdAt }

        // Past: not active AND (approved || rejected)
        let past = all
            .filter { !$0.active && ($0.approved == .approved || $0.approved == .rejected) }
            .sorted { $0.createdAt > $1.createdAt }

        return (active, requested, past)
    }
}

// MARK: - View

@MainActor
struct MyPassesView: View {
    // Collapsible sections
    @State private var showRequestedPasses = true
    @State private var showPastPasses = false

    @StateObject private var vm: MyPassesViewModel

    init(viewModel: MyPassesViewModel? = nil) {
        _vm = StateObject(wrappedValue: viewModel ?? MyPassesViewModel())
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {

                    // --- ACTIVE CARD (only if exists) ---
                    if let p = vm.activePass {
                        ActiveCard(pass: p, onEnd: { Task { await vm.end(p) } })
                            .accessibilityIdentifier("active_card")
                    }

                    // --- REQUESTED (collapsible, excludes active) ---
                    SectionHeader(
                        title: "Requested Passes",
                        color: .blue,
                        expanded: $showRequestedPasses
                    )
                    if showRequestedPasses {
                        VStack(spacing: 8) {
                            if vm.requested.isEmpty {
                                EmptyHint(text: "No requested passes")
                            } else {
                                ForEach(vm.requested) { p in
                                    NavigationLink {
                                        PassDetailView(pass: p).toolbar(.hidden, for: .tabBar)
                                    } label: {
                                        PassPreview(
                                            from: p.fromRoom,
                                            to: p.toRoom,
                                            startAt: p.createdAt,                 // requested at
                                            durationMinutes: p.duration ?? 0,
                                            approval: .init(from: p.approved)
                                        )
                                    }
                                }
                            }
                        }
                        .transition(.opacity)
                        .accessibilityIdentifier("requested_list")
                    }

                    // --- PAST (collapsible) ---
                    SectionHeader(
                        title: "Past Passes",
                        color: Color(.purple),
                        expanded: $showPastPasses
                    )
                    if showPastPasses {
                        VStack(spacing: 8) {
                            if vm.past.isEmpty {
                                EmptyHint(text: "No past passes yet")
                            } else {
                                ForEach(vm.past) { p in
                                    NavigationLink {
                                        PassDetailView(pass: p).toolbar(.hidden, for: .tabBar)
                                    } label: {
                                        PassPreview(
                                            from: p.fromRoom,
                                            to: p.toRoom,
                                            startAt: p.startTime ?? p.createdAt,  // started if known, else requested
                                            durationMinutes: p.duration ?? 0,
                                            approval: .init(from: p.approved)
                                        )
                                    }
                                }
                            }
                        }
                        .transition(.opacity)
                        .accessibilityIdentifier("past_list")
                    }

                    if let err = vm.error {
                        Text(err).foregroundStyle(.red).font(.footnote).padding(.top, 4)
                    }
                    if vm.isLoading {
                        ProgressView().padding(.top, 4)
                    }
                }
                .padding(.top, 16)
            }
            .padding(.horizontal, 16)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 8) {
                        Image(systemName: "hammer.circle").font(.title2).bold()
                        Text("corepass").font(.title2).bold()
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color(.systemGray6))
            .toolbarBackground(Color(.white), for: .navigationBar, .tabBar)
            .toolbarBackground(.visible, for: .navigationBar, .tabBar)
        }
        .onAppear { vm.start() }
        .onDisappear { vm.stop() }
    }
}

// MARK: - Shared UI bits (unchanged)

private struct SectionHeader: View {
    let title: String
    let color: Color
    @Binding var expanded: Bool

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.18)) { expanded.toggle() }
        } label: {
            HStack(spacing: 8) {
                Text(title)
                    .font(.title2).bold()
                    .foregroundStyle(color)
                Image(systemName: "chevron.down")
                    .rotationEffect(.degrees(expanded ? 0 : 180))
                Spacer()
            }
        }
        .buttonStyle(.plain)
    }
}

private struct EmptyHint: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color(.systemGray4), lineWidth: 2)
            )
    }
}

#Preview("MyPasses — Mocked") {
    // Preview with a mock service + fake uid
    struct PreviewService: PassesServiceProtocol {
        func startListening(for uid: String, onChange: @escaping ([Pass]) -> Void) {
            // Seed a realistic set
            let base = Date()
            let passes: [Pass] = [
                Pass(id: "a1", author: uid, fromRoom: "C200", toRoom: "Library",
                     createdAt: base.addingTimeInterval(-1200),
                     approved: .approved, startTime: base.addingTimeInterval(-300),
                     duration: 10, active: true),
                Pass(id: "r1", author: uid, fromRoom: "Math 201", toRoom: "Nurse",
                     createdAt: base.addingTimeInterval(-600),
                     approved: .pending, startTime: nil,
                     duration: 10, active: false),
                Pass(id: "p1", author: uid, fromRoom: "Science 101", toRoom: "East Restroom",
                     createdAt: base.addingTimeInterval(-3600),
                     approved: .rejected, startTime: nil,
                     duration: 15, active: false),
            ]
            onChange(passes)
        }
        func stopListening() {}
        func endPass(id: String) async throws { /* no-op */ }
    }

    // Ensure a fake session UID for preview
    Services.session = MockSession(uid: "preview-uid")

    let vm = MyPassesViewModel(service: PreviewService())
    return MyPassesView(viewModel: vm)
        .background(Color(.systemGray6))
}
