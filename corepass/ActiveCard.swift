import SwiftUI

/// Compact card showing the *currently running* pass.
struct ActiveCard: View {
    let pass: Pass
    var onEnd: (() -> Void)? = nil
    // MARK: - Derived (safe) values
    private var startedAt: Date { pass.startTime ?? .now }     // graceful fallback if data incomplete
    private var durationMinutes: Int { max(0, pass.duration ?? 0) }

    // MARK: - Style tokens
    private enum UI {
        static let corner: CGFloat = 12
        static let hPad: CGFloat = 16
        static let vSpacing: CGFloat = 8
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: UI.vSpacing) {
                // Title
                Text("Active Pass")
                    .font(.subheadline).bold()
                    .foregroundStyle(.green)
                    .accessibilityAddTraits(.isHeader)

                // Route line
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(pass.fromRoom)
                        .font(.subheadline)
                        .lineLimit(1)
                    Image(systemName: "arrow.right").font(.caption2)
                    Text(pass.toRoom)
                        .font(.subheadline)
                        .lineLimit(1)
                    Spacer()
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("From \(pass.fromRoom) to \(pass.toRoom)")

                // Live timer/progress
                TimelineView(.periodic(from: .now, by: 1)) { ctx in
                    let p = Self.progress(startAt: startedAt, durationMinutes: durationMinutes, now: ctx.date)

                    VStack(alignment: .leading, spacing: 6) {
                        ProgressView(value: p.fraction)
                            .progressViewStyle(.linear)
                            .tint(.green)
                            .accessibilityLabel("Progress")
                            .accessibilityValue("\(Int((p.fraction * 100).rounded())) percent")

                        Text(p.remainingLabel)
                            .font(.caption)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                            .accessibilityLabel("Time remaining")
                            .accessibilityValue(p.remainingAccessibility)
                    }
                }

                // Actions
                HStack(spacing: 4) {
                    Button(action: { (onEnd ?? { })() }) {
                        Label("End Pass", systemImage: "x.circle.fill")
                            .font(.caption).bold()
                            .foregroundStyle(.white)
                            .padding(8)
                    }
                    .background(.red, in: RoundedRectangle(cornerRadius: UI.corner, style: .continuous))
                    .accessibilityIdentifier("activecard_end_button")

                    Spacer()

                    NavigationLink {
                        PassDetailView(pass: pass)
                            .toolbar(.hidden, for: .tabBar)
                    } label: {
                        Label("Fullscreen", systemImage: "arrow.up.left.and.arrow.down.right")
                            .font(.caption).bold()
                            .foregroundStyle(.black)
                            .padding(8)
                            .background(.white, in: RoundedRectangle(cornerRadius: UI.corner, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: UI.corner).strokeBorder())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("activecard_fullscreen_button")
                }
            }
            Spacer()
        }
        .padding(UI.hPad)
        .background(.white, in: RoundedRectangle(cornerRadius: UI.corner, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: UI.corner, style: .continuous)
                .strokeBorder(Color.black.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Active pass")
    }
}

// MARK: - Testable progress math

extension ActiveCard {
    struct Progress {
        /// 0...1 (clamped)
        let fraction: Double
        /// Whole minutes remaining (never negative)
        let remainingMinutes: Int

        var remainingLabel: String {
            remainingMinutes == 1 ? "1 minute remaining" : "\(remainingMinutes) minutes remaining"
        }
        var remainingAccessibility: String { remainingLabel }
    }

    /// Pure function used by the view and unit tests.
    static func progress(startAt: Date, durationMinutes: Int, now: Date) -> Progress {
        print(startAt)
        let total = max(0, durationMinutes) * 60
        guard total > 0 else { return Progress(fraction: 0, remainingMinutes: 0) }
        
        let elapsed = max(0, Int(now.timeIntervalSince(startAt)))
        let clampedElapsed = min(elapsed, total)
        let fraction = Double(clampedElapsed) / Double(total)
        let remaining = max(0, total - clampedElapsed)
        return Progress(fraction: fraction, remainingMinutes: Int(ceil(Double(remaining) / 60.0)))
    }
}

#Preview("ActiveCard — demo") {
    // Approved + active sample pass
    let demo = Pass(
        id: "demo",
        author: "uid",
        fromRoom: "C200",
        toRoom: "Library",
        createdAt: .now.addingTimeInterval(-600),
        approved: .approved,
        startTime: .now.addingTimeInterval(-120), // started 2 min ago
        duration: 10,                              // 10 min total
        active: true
    )
    NavigationStack {
        ActiveCard(pass: demo, onEnd: { print("End tapped (preview)") })
            .padding()
            .background(Color(.systemGray6))
    }
}
