import SwiftUI

struct PassDetailView: View {
    let pass: Pass

    private var uiStatus: ApprovalStatus { .init(from: pass.approved) }

    // Semantics
    private var isRunning: Bool { pass.approved == .approved && pass.active }

    private var startedAt: Date? { pass.startTime }                  // only for approved passes
    private var requestedAt: Date { pass.createdAt }                 // always exists
    private var durationMinutes: Int? { pass.duration }              // optional

    private var endedAt: Date? {
        guard let start = startedAt, let mins = durationMinutes else { return nil }
        return start.addingTimeInterval(TimeInterval(mins * 60))
    }

    private var statusIcon: String {
        switch pass.approved {
        case .approved: "checkmark.circle.fill"
        case .pending:  "hourglass.circle.fill"
        case .rejected: "xmark.circle.fill"
        }
    }

    var body: some View {
        ZStack (alignment: .top){
            uiStatus.tint.ignoresSafeArea()

            VStack(alignment: .center, spacing: 20) {
                // Status pill
                Label(uiStatus.display, systemImage: statusIcon)
                    .font(.headline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.white.opacity(0.18), in: Capsule())

                // Route (big)
                VStack(alignment: .leading, spacing: 10) {
                    Text(pass.fromRoom)
                        .font(.system(size: 40, weight: .heavy, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)

                    HStack(spacing: 12) {
                        Image(systemName: "arrow.turn.down.right")
                            .font(.system(size: 26, weight: .bold))
                        Text(pass.toRoom)
                            .font(.system(size: 40, weight: .heavy, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }
                }

                // Bottom content
                BottomContent(
                    uiStatus: uiStatus,
                    isRunning: isRunning,
                    requestedAt: requestedAt,
                    startedAt: startedAt,
                    endedAt: endedAt,
                    durationMinutes: durationMinutes
                )
            }
            .padding(.horizontal, 12)
            .padding(.top, 16)
            .padding(.bottom, 12)
            .foregroundStyle(.white)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(uiStatus.tint, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

// MARK: - Bottom Content

private struct BottomContent: View {
    let uiStatus: ApprovalStatus
    let isRunning: Bool
    let requestedAt: Date
    let startedAt: Date?
    let endedAt: Date?
    let durationMinutes: Int?

    var body: some View {
        VStack(alignment: .center, spacing: 8) {   // was 16
            if isRunning, let start = startedAt, let mins = durationMinutes {

                RunningTimerView(startAt: start, durationMinutes: mins)
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(.white.opacity(0.15))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(.white.opacity(0.28), lineWidth: 1)
                    )
                    .padding(.horizontal, 8)
                

                HStack(alignment: .center, spacing: 16) {
                    BigInfo(icon: "clock",
                            title: "Started",
                            value: start.formatted(date: .omitted, time: .shortened))

                    VSeparator()   // <-- instead of Divider()

                    BigInfo(icon: "calendar.badge.clock",
                            title: "Ends",
                            value: (start.addingTimeInterval(TimeInterval(mins * 60)))
                                .formatted(date: .omitted, time: .shortened))

                    VSeparator()   // <-- instead of Divider()

                    BigInfo(icon: "hourglass",
                            title: "Duration",
                            value: "\(mins) min")
                }
                .fixedSize(horizontal: false, vertical: true)   // collapse to intrinsic height
                .padding(.horizontal, 8)
                .padding(.top, 20)
            } else {
                // Not running - full background for all content
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.white.opacity(0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(.white.opacity(0.28), lineWidth: 1)
                        )

                    VStack(alignment: .leading, spacing: 12) {
                        // Big heading by status
                        HStack(spacing: 10) {
                            Image(systemName:
                                  uiStatus == .pending ? "hourglass.circle.fill" :
                                  (uiStatus == .rejected ? "xmark.circle.fill" : "checkmark.circle.fill"))
                                .font(.system(size: 32, weight: .bold))
                            Text(
                                uiStatus == .pending ? "Awaiting Approval" :
                                (uiStatus == .rejected ? "Rejected" : "Approved")
                            )
                            .font(.system(size: 32, weight: .heavy, design: .rounded))
                        }

                        // Requested at always shows
                        BigLine(icon: "paperplane", label: "Requested",
                                value: requestedAt.formatted(date: .abbreviated, time: .shortened))

                        // If we have a start for approved-but-not-active, show it
                        if uiStatus == .approved, let start = startedAt {
                            BigLine(icon: "clock", label: "Started",
                                    value: start.formatted(date: .abbreviated, time: .shortened))
                        }

                        // If we can compute an end, show it
                        if let end = endedAt {
                            BigLine(icon: "calendar.badge.clock", label: "Ended",
                                    value: end.formatted(date: .abbreviated, time: .shortened))
                        }

                        // Duration if known
                        if let mins = durationMinutes {
                            BigLine(icon: "hourglass", label: "Duration", value: "\(mins) min")
                        }
                    }
                    .padding(20)
                }
            }
        }
    }
}

// MARK: - Running Timer (uses startTime only)

private struct RunningTimerView: View {
    let startAt: Date
    let durationMinutes: Int

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { ctx in
            let now = ctx.date
            let total = Double(max(durationMinutes, 0) * 60)
            let elapsed = max(0, now.timeIntervalSince(startAt))
            let remaining = max(0, total - elapsed)
            let fraction = total > 0 ? min(elapsed / total, 1) : 0

            VStack(alignment: .leading, spacing: 14) {
                Text("Time Remaining")
                    .font(.headline)

                Text(Self.mmss(from: remaining))
                    .font(.system(size: 64, weight: .heavy, design: .rounded))
                    .monospacedDigit()

                ProgressBar(fraction: fraction)
                    .frame(height: 16)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(.white.opacity(0.4), lineWidth: 1))
            }
        }
    }

    private static func mmss(from seconds: Double) -> String {
        let s = max(0, Int(seconds.rounded()))
        let m = s / 60
        let r = s % 60
        return String(format: "%02d:%02d", m, r)
    }
}

// MARK: - Reusable bits

private struct ProgressBar: View {
    let fraction: Double
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack(alignment: .leading) {
                Rectangle().fill(.white.opacity(0.2))
                Rectangle().fill(.white)
                    .frame(width: max(0, min(1, fraction)) * w)
            }
        }
    }
}

private struct BigInfo: View {
    let icon: String
    let title: String
    let value: String
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.subheadline)
            .foregroundStyle(.white.opacity(0.9))

            Text(value)
                .font(.title2.bold())
                .monospacedDigit()
        }
    }
}

private struct BigLine: View {
    let icon: String
    let label: String
    let value: String
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
            Text(label).font(.headline)
            Spacer()
            Text(value).font(.title3.bold()).monospacedDigit()
        }
        .padding(.vertical, 4)
    }
}

private struct VSeparator: View {
    var body: some View {
        Rectangle()
            .fill(.white.opacity(0.25))
            .frame(width: 1, height: 28)   // keep it around the text height
            .cornerRadius(0.5)
    }
}


// Mapping
private extension ApprovalStatus {
    init(from status: PassStatus) {
        switch status {
        case .pending:  self = .pending
        case .approved: self = .approved
        case .rejected: self = .rejected
        }
    }
}

#Preview {
    NavigationStack {
        // Running
        PassDetailView(pass: Pass(
            id: "a", author: "u", fromRoom: "Math 201", toRoom: "Nurse",
            createdAt: .now.addingTimeInterval(-3600),
            approved: .approved, startTime: .now.addingTimeInterval(-120),
            duration: 10, active: true
        ))
    }
}
