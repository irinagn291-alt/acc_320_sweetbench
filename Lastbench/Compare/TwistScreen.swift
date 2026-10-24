import SwiftUI

/// Split-call progress. A verdict files only after four runs and fourteen days.
struct TwistScreen: View {
    @ObservedObject var session: CompareBenchSession
    var onChangePair: () -> Void = {}
    @State private var reloading = false
    @State private var logging = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.s16) {
                    Text("Split")
                        .font(TypeScale.font(.title))
                        .foregroundStyle(DesignTokens.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Both shoes need four logged runs and fourteen days. Then the bench names the cheaper one.")
                        .font(TypeScale.font(.body))
                        .foregroundStyle(DesignTokens.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    if session.presentation.left != nil, session.presentation.right != nil {
                        Button {
                            logRun()
                        } label: {
                            Text(logTitle)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                        .buttonStyle(BenchPressStyle(kind: .primary))
                        .disabled(!session.isReady || logging)
                        Button {
                            onChangePair()
                        } label: {
                            Text("Pair shoes")
                        }
                        .buttonStyle(BenchPressStyle(kind: .secondary))
                    }
                    if let note = session.presentation.loadNote {
                        Text(note)
                            .font(TypeScale.font(.body))
                            .foregroundStyle(DesignTokens.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        Button {
                            reload()
                        } label: {
                            Text("Retry")
                        }
                        .buttonStyle(BenchPressStyle(kind: .primary))
                        .disabled(reloading)
                    }
                    if session.presentation.left == nil || session.presentation.right == nil {
                        FullEmpty(
                            image: "lsb_EmptyRotationCutout",
                            title: "No pair yet.",
                            line: "Pair two shoes on the bench.",
                            actionTitle: "Retry"
                        ) {
                            reload()
                        }
                    } else {
                        if let left = session.presentation.left {
                            gate(left, title: "Left shoe")
                        }
                        if let right = session.presentation.right {
                            gate(right, title: "Right shoe")
                        }
                        if let verdict = session.presentation.verdict {
                            verdictRow(verdict)
                        }
                    }
                }
                .padding(Spacing.s16)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(DesignTokens.bg)
            .navigationTitle("Split call")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    CloseControl()
                }
            }
        }
        .tint(DesignTokens.ink)
    }

    private func gate(_ pane: ComparePresentation.PaneReading, title: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s8) {
            Text(title)
                .font(TypeScale.font(.meta))
                .tracking(TypeScale.tracking(.meta))
                .textCase(.uppercase)
                .foregroundStyle(DesignTokens.muted)
            Text(pane.nickname)
                .font(TypeScale.font(.title))
                .foregroundStyle(DesignTokens.ink)
                .lineLimit(1)
                .truncationMode(.tail)
            HStack(spacing: Spacing.s8) {
                Text(pane.mileCount, format: .number.precision(.fractionLength(0)))
                    .foregroundStyle(DesignTokens.accent)
                    .contentTransition(.numericText(value: Double(pane.mileCount)))
                    .animation(Motion.press, value: pane.mileCount)
                Text("of")
                    .foregroundStyle(DesignTokens.muted)
                Text(RotationEfficiency.verdictMileCount, format: .number.precision(.fractionLength(0)))
                Text("runs")
            }
            .font(TypeScale.font(.title))
            .foregroundStyle(DesignTokens.ink)
            .monospacedDigit()
            HStack(spacing: Spacing.s8) {
                Text(pane.ageDays, format: .number.precision(.fractionLength(0)))
                    .foregroundStyle(DesignTokens.accent)
                Text("of")
                    .foregroundStyle(DesignTokens.muted)
                Text(RotationEfficiency.verdictAgeDays, format: .number.precision(.fractionLength(0)))
                Text("days")
            }
            .font(TypeScale.font(.call))
            .foregroundStyle(DesignTokens.ink)
            .monospacedDigit()
        }
        .padding(Spacing.s16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .surfacePlate()
    }

    private func verdictRow(_ verdict: VerdictChip) -> some View {
        HStack(spacing: Spacing.s12) {
            Image("lsb_VerdictBadgeCutout")
                .resizable()
                .scaledToFit()
                .frame(width: Spacing.s48, height: Spacing.s48)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Spacing.s4) {
                Text("Cheaper")
                    .font(TypeScale.font(.meta))
                    .foregroundStyle(DesignTokens.muted)
                Text(verdict.lowerCostPerMile, format: .currency(code: "USD").precision(.fractionLength(0...1)))
                    .font(TypeScale.font(.title))
                    .foregroundStyle(DesignTokens.accent)
                    .monospacedDigit()
            }
            Spacer(minLength: Spacing.s8)
        }
        .padding(Spacing.s16)
        .surfacePlate()
    }

    private var logTitle: String {
        if let name = laggingPane?.nickname {
            return "Log a run on \(name)"
        }
        return "Log a run"
    }

    private var laggingPane: ComparePresentation.PaneReading? {
        guard let left = session.presentation.left, let right = session.presentation.right else {
            return session.presentation.left ?? session.presentation.right
        }
        if left.mileCount < right.mileCount { return left }
        if right.mileCount < left.mileCount { return right }
        return left
    }

    private func logRun() {
        guard !logging, let pane = laggingPane else { return }
        logging = true
        session.mile(lastID: pane.id, distance: 1)
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 180_000_000)
            logging = false
        }
    }

    private func reload() {
        guard !reloading else { return }
        reloading = true
        Task { @MainActor in
            await session.reload()
            reloading = false
        }
    }
}
