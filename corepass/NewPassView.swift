import SwiftUI
import FirebaseFirestore

// MARK: - Constants
private let SCHOOL_ID = "abcdefghijklmnopqrstuv" // as requested

// MARK: - Services (protocols)

protocol RoomsServiceProtocol {
    func fetchRooms() async throws -> [String]
}

protocol PassSubmitServiceProtocol {
    func submitPendingPass(from: String, to: String, duration: Int?, uid: String) async throws
}

// MARK: - Default Firestore implementations

final class FirestoreRoomsService: RoomsServiceProtocol {
    func fetchRooms() async throws -> [String] {
        let snap = try await Firestore.firestore().collection("rooms").getDocuments()
        // Unique + sorted room names
        let names = snap.documents.compactMap { $0.get("name") as? String }
        return Array(Set(names)).sorted()
    }
}

final class FirestorePassSubmitService: PassSubmitServiceProtocol {
    func submitPendingPass(from: String, to: String, duration: Int?, uid: String) async throws {
        var data: [String: Any] = [
            "author": uid,
            "fromRoom": from,
            "toRoom": to,
            "created_at": FieldValue.serverTimestamp(),
            "approved": "pending",
            "active": false,
            "schoolId": SCHOOL_ID
            // "start_time" intentionally omitted (empty)
        ]
        if let duration { data["duration"] = duration }
        try await Firestore.firestore().collection("passes").addDocument(data: data)
    }
}

// MARK: - ViewModel

@MainActor
final class NewPassViewModel: ObservableObject {
    // Inputs
    @Published var start: String?
    @Published var destination: String?
    @Published var durationMinutes: Int? = 10

    // Rooms
    @Published var allRooms: [String] = []
    @Published var isLoadingRooms = true
    @Published var loadError: String?

    // Submit state
    @Published var isSubmitting = false
    @Published var submitMessage: String?

    // Services
    private let roomsService: RoomsServiceProtocol
    private let submitService: PassSubmitServiceProtocol

    init(
        roomsService: RoomsServiceProtocol = FirestoreRoomsService(),
        submitService: PassSubmitServiceProtocol = FirestorePassSubmitService()
    ) {
        self.roomsService = roomsService
        self.submitService = submitService
    }

    var canSubmit: Bool {
        guard !isLoadingRooms,
              let s = start, !s.isEmpty,
              let d = destination, !d.isEmpty,
              s != d,
              Services.session.uid != nil
        else { return false }
        return true
    }

    func loadRooms() async {
        isLoadingRooms = true
        loadError = nil
        do {
            let names = try await roomsService.fetchRooms()
            allRooms = names
            isLoadingRooms = false
        } catch {
            loadError = error.localizedDescription
            isLoadingRooms = false
        }
    }

    func submit() async {
        guard canSubmit,
              let s = start, let d = destination,
              let uid = Services.session.uid
        else { return }

        isSubmitting = true
        defer { isSubmitting = false }

        do {
            try await submitService.submitPendingPass(
                from: s, to: d, duration: durationMinutes, uid: uid
            )
            submitMessage = "Your pass request was sent."
            // Reset picks (keep duration)
            start = nil
            destination = nil
        } catch {
            submitMessage = "Failed to submit: \(error.localizedDescription)"
        }
    }
}

// MARK: - View

@MainActor
struct NewPassView: View {
    @StateObject private var vm: NewPassViewModel

    // Avoid default param constructors on @MainActor types — resolve inside init.
    init(viewModel: NewPassViewModel? = nil) {
        _vm = StateObject(wrappedValue: viewModel ?? NewPassViewModel())
    }

    // Simple presets for duration (minutes)
    private let durationOptions = [5, 10, 15, 20, 30]

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {

                // START
                PickerField(
                    title: "Where are you starting from?",
                    placeholder: vm.isLoadingRooms ? "Loading rooms…" : "Click to select starting point",
                    options: vm.allRooms,
                    selection: $vm.start
                )
                .allowsHitTesting(!vm.isLoadingRooms)

                // DESTINATION
                PickerField(
                    title: "Where are you going?",
                    placeholder: vm.isLoadingRooms ? "Loading rooms…" : "Click to select destination",
                    options: vm.allRooms,
                    selection: $vm.destination
                )
                .allowsHitTesting(!vm.isLoadingRooms)

                // DURATION
                VStack(alignment: .leading, spacing: 12) {
                    Text("Duration").font(.headline)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 8) {
                        ForEach(durationOptions, id: \.self) { mins in
                            Button(action: { vm.durationMinutes = mins }) {
                                Text("\(mins) min")
                                    .font(.subheadline.weight(.medium))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(vm.durationMinutes == mins ? Color.black : Color(.systemGray5))
                                    .foregroundStyle(vm.durationMinutes == mins ? .white : .black)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(mins) minutes")
                            .accessibilityAddTraits(vm.durationMinutes == mins ? .isSelected : [])
                        }
                    }
                }
                .padding(.top, 8)

                Spacer()

                // SUBMIT
                Button(action: { Task { await vm.submit() } }) {
                    HStack {
                        if vm.isSubmitting { ProgressView().tint(.white) }
                        Text(vm.isSubmitting ? "Submitting…" : "Submit Request")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(vm.canSubmit ? Color.blue : Color.gray)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .disabled(!vm.canSubmit || vm.isSubmitting)
                .accessibilityIdentifier("newpass_submit_button")

                if let err = vm.loadError {
                    Text(err).foregroundStyle(.red).font(.footnote)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 8) {
                        Image(systemName: "hammer.circle").font(.title2).bold()
                        Text("corepass").font(.title2).bold()
                    }
                }
            }
            .background(Color(.systemGray6).ignoresSafeArea())
            .toolbarBackground(Color(.white), for: .navigationBar, .tabBar)
            .toolbarBackground(.visible, for: .navigationBar, .tabBar)
            .task { await vm.loadRooms() } // load on appear
            .alert("Request Submitted", isPresented: Binding(
                get: { vm.submitMessage != nil },
                set: { if !$0 { vm.submitMessage = nil } }
            )) {
                Button("OK", role: .cancel) { vm.submitMessage = nil }
            } message: {
                Text(vm.submitMessage ?? "")
            }
        }
    }
}

#Preview("New Pass — Mocked") {
    // Preview: fake session uid + mocked services
    Services.session = MockSession(uid: "preview-uid")

    final class MockRooms: RoomsServiceProtocol {
        func fetchRooms() async throws -> [String] { ["Math 201", "Science 101", "C200", "Library", "Nurse"].sorted() }
    }
    final class MockSubmit: PassSubmitServiceProtocol {
        func submitPendingPass(from: String, to: String, duration: Int?, uid: String) async throws {
            print("Mock submit: \(from) → \(to), \(duration ?? 0) min, uid \(uid)")
        }
    }

    let vm = NewPassViewModel(roomsService: MockRooms(), submitService: MockSubmit())
    return NewPassView(viewModel: vm)
        .background(Color(.systemGray6))
}
