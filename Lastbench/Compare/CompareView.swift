import SwiftUI

/// Locked compare bench. The masthead, split panes, and mile verb stay here.
struct CompareView: View {
    @ObservedObject var session: CompareBenchSession
    var open: (BenchCover) -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var distanceText = ""
    @State private var mileBusy = false
    @State private var commits = 0
    @FocusState private var distanceFocused: Bool

    var body: some View {
        NavigationStack {
            scroll
                .toolbar(.hidden, for: .navigationBar)
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Button("Done") {
                            distanceFocused = false
                        }
                        .frame(minHeight: Hit.min)
                    }
                }
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: commits)
    }

    private var scroll: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s16) {
                masthead
                Rectangle()
                    .fill(DesignTokens.muted)
                    .frame(height: Elevation.hairline)
                    .accessibilityHidden(true)
                shoePlates
                distanceField
                mileButtons
                if let refusal = BenchCopy.refusal(session.presentation.refusal) {
                    Text(refusal)
                        .font(TypeScale.font(.body))
                        .foregroundStyle(DesignTokens.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
                destinations
                if let verdict = session.presentation.verdict {
                    verdictBlock(verdict)
                }
                latestOuting
            }
            .padding(.horizontal, Spacing.s16)
            .padding(.top, Spacing.s16)
            .padding(.bottom, Spacing.s32)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollDismissesKeyboard(.immediately)
        .background(DesignTokens.bg)
    }

    private var masthead: some View {
        VStack(alignment: .leading, spacing: Spacing.s8) {
            Text("Mile")
                .font(TypeScale.font(.title))
                .textCase(.uppercase)
            .foregroundStyle(DesignTokens.ink)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)
            Text(jobLine)
                .font(TypeScale.font(.body))
                .foregroundStyle(DesignTokens.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var jobLine: String {
        switch session.presentation.phase {
        case .matched:
            "Log today's distance on the left shoe."
        default:
            BenchCopy.phase(session.presentation.phase)
        }
    }

    private var shoePlates: some View {
        VStack(spacing: Spacing.s8) {
            shoePlate(leadModel)
            shoePlate(railModel)
        }
    }

    private func shoePlate(_ model: PaneFaceModel) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s4) {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.s8) {
                Text(model.nickname)
                    .font(TypeScale.font(.call))
                    .foregroundStyle(DesignTokens.ink)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer(minLength: Spacing.s8)
                GradeChip(band: model.band)
            }
            if model.hasCost {
                HStack(alignment: .firstTextBaseline, spacing: Spacing.s8) {
                    Text(model.costPerMile, format: .currency(code: "USD").precision(.fractionLength(0...1)))
                        .font(TypeScale.font(.title))
                        .foregroundStyle(DesignTokens.accent)
                        .monospacedDigit()
                        .fixedSize(horizontal: true, vertical: true)
                        .layoutPriority(1)
                    Text("per mile")
                        .font(TypeScale.font(.body))
                        .foregroundStyle(DesignTokens.ink)
                        .fixedSize(horizontal: true, vertical: true)
                        .layoutPriority(1)
                }
                .lineLimit(1)
            } else {
                Text("No miles yet.")
                    .font(TypeScale.font(.body))
                    .foregroundStyle(DesignTokens.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(Spacing.s12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .surfacePlate()
        .accessibilityElement(children: .combine)
    }

    private var distanceField: some View {
        VStack(alignment: .leading, spacing: Spacing.s8) {
            Text(session.presentation.left?.nickname ?? "Left shoe")
                .font(TypeScale.font(.meta))
                .tracking(TypeScale.tracking(.meta))
                .textCase(.uppercase)
                .foregroundStyle(DesignTokens.muted)
                .lineLimit(1)
                .truncationMode(.tail)
            HStack(alignment: .firstTextBaseline, spacing: Spacing.s8) {
                TextField(
                    "",
                    text: $distanceText,
                    prompt: Text("Type miles").foregroundStyle(DesignTokens.ink)
                )
                .keyboardType(.decimalPad)
                .focused($distanceFocused)
                .font(TypeScale.font(.title))
                .foregroundStyle(DesignTokens.ink)
                .fixedSize(horizontal: false, vertical: true)
                Text(BenchCopy.unit(session.presentation.distanceUnit))
                    .font(TypeScale.font(.body))
                    .foregroundStyle(DesignTokens.ink)
                    .fixedSize(horizontal: true, vertical: true)
            }
            .padding(Spacing.s12)
            .frame(maxWidth: .infinity, minHeight: Hit.min, alignment: .leading)
            .surfacePlate()
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Distance today")
        }
    }

    private var mileButtons: some View {
        VStack(spacing: Spacing.s8) {
            Button {
                commit(session.presentation.left?.id)
            } label: {
                Text("Log mile")
            }
            .buttonStyle(BenchPressStyle(kind: .primary))
            .disabled(!session.isReady || mileBusy)
            .accessibilityHint("Logs distance for the left shoe.")
            Button {
                commit(session.presentation.right?.id)
            } label: {
                Text(rightTitle)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .buttonStyle(BenchPressStyle(kind: .secondary))
            .disabled(!session.isReady || mileBusy)
            .accessibilityHint("Logs distance for the right shoe.")
        }
    }

    private var rightTitle: String {
        if let name = session.presentation.right?.nickname {
            return "Log \(name)"
        }
        return "Log right shoe"
    }

    private func verdictBlock(_ verdict: VerdictChip) -> some View {
        HStack(alignment: .center, spacing: Spacing.s12) {
                Image("lsb_VerdictBadgeCutout")
                    .resizable()
                    .scaledToFit()
                    .frame(width: Spacing.s48, height: Spacing.s48)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: Spacing.s4) {
                    Text("Split call")
                        .font(TypeScale.font(.meta))
                        .tracking(TypeScale.tracking(.meta))
                        .textCase(.uppercase)
                        .foregroundStyle(DesignTokens.muted)
                    HStack(spacing: Spacing.s8) {
                        Text(verdict.lowerCostPerMile, format: .currency(code: "USD").precision(.fractionLength(0...1)))
                            .foregroundStyle(DesignTokens.accent)
                        Text("beats")
                            .foregroundStyle(DesignTokens.muted)
                        Text(verdict.higherCostPerMile, format: .currency(code: "USD").precision(.fractionLength(0...1)))
                            .foregroundStyle(DesignTokens.ink)
                    }
                    .font(TypeScale.font(.title))
                    .monospacedDigit()
                    .fixedSize(horizontal: false, vertical: true)
                    Text(cheaperName(verdict))
                        .font(TypeScale.font(.body))
                        .foregroundStyle(DesignTokens.ink)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                Spacer(minLength: Spacing.s8)
            }
            .padding(Spacing.s16)
            .surfacePlate()
            .animation(reduceMotion ? nil : Motion.press, value: verdict.id)
    }

    private var latestOuting: some View {
        VStack(alignment: .leading, spacing: Spacing.s8) {
            Text("Latest outing")
                .font(TypeScale.font(.meta))
                .tracking(TypeScale.tracking(.meta))
                .textCase(.uppercase)
                .foregroundStyle(DesignTokens.muted)
            if let outing = session.presentation.outings.first {
                HStack(spacing: Spacing.s12) {
                    Text(outing.nickname)
                        .font(TypeScale.font(.call))
                        .foregroundStyle(DesignTokens.ink)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Spacer(minLength: Spacing.s8)
                    Text(outing.distance, format: .number.precision(.fractionLength(0...1)))
                        .font(TypeScale.font(.title))
                        .foregroundStyle(DesignTokens.accent)
                        .monospacedDigit()
                        .contentTransition(.numericText(value: outing.distance))
                        .animation(Motion.press, value: outing.distance)
                        .layoutPriority(1)
                    Text(BenchCopy.unit(session.presentation.distanceUnit))
                        .font(TypeScale.font(.meta))
                        .foregroundStyle(DesignTokens.muted)
                }
            } else {
                Text("No outing yet.")
                    .font(TypeScale.font(.body))
                    .foregroundStyle(DesignTokens.ink)
            }
            Button {
                guard !mileBusy else { return }
                mileBusy = true
                session.peel()
                releaseMile()
            } label: {
                Text("Undo outing")
            }
            .buttonStyle(BenchPressStyle(kind: .secondary))
            .disabled(!session.isReady || mileBusy || !session.presentation.canPeel)
        }
        .padding(Spacing.s16)
        .surfacePlate()
    }

    private var destinations: some View {
        VStack(alignment: .leading, spacing: Spacing.s8) {
            Text("Bench")
                .font(TypeScale.font(.meta))
                .tracking(TypeScale.tracking(.meta))
                .textCase(.uppercase)
                .foregroundStyle(DesignTokens.muted)
            DestinationRow(title: "Closet", symbol: "square.stack") { open(.library) }
            DestinationRow(title: "Pair shoes", symbol: "rectangle.split.2x1") { open(.pair) }
            DestinationRow(title: "Split call", symbol: "square.split.2x1") { open(.twist) }
            DestinationRow(title: "Ranks", symbol: "chart.bar") { open(.insights) }
            DestinationRow(title: "Outings", symbol: "list.bullet") { open(.ledger) }
            DestinationRow(title: "Preferences", symbol: "slider.horizontal.3") { open(.settings) }
        }
    }

    private var leadModel: PaneFaceModel {
        if let left = session.presentation.left {
            return .reading(left, role: .lead, unit: session.presentation.distanceUnit)
        }
        return .unpaired(role: .lead, unit: session.presentation.distanceUnit)
    }

    private var railModel: PaneFaceModel {
        if let right = session.presentation.right {
            return .reading(right, role: .rail, unit: session.presentation.distanceUnit)
        }
        return .unpaired(role: .rail, unit: session.presentation.distanceUnit)
    }

    private func cheaperName(_ verdict: VerdictChip) -> String {
        session.presentation.shelf.first { $0.id == verdict.lowerLastID }?.nickname ?? "Cheaper shoe"
    }

    private func commit(_ lastID: UUID?) {
        guard !mileBusy else { return }
        mileBusy = true
        distanceFocused = false
        let distance = DecimalInput.distance(from: distanceText) ?? 0
        let before = session.presentation.outings.count
        session.mile(lastID: lastID ?? UUID(), distance: distance)
        if session.presentation.refusal == nil, session.presentation.outings.count > before {
            commits += 1
            distanceText = ""
        }
        releaseMile()
    }

    private func releaseMile() {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 180_000_000)
            mileBusy = false
        }
    }
}

struct CompareStage: UIViewControllerRepresentable {
    var lead: PaneFaceModel
    var rail: PaneFaceModel
    var fraction: CGFloat
    var burst: Int

    func makeUIViewController(context: Context) -> CompareContainerViewController {
        CompareContainerViewController.loadFromStoryboard()
    }

    func updateUIViewController(_ controller: CompareContainerViewController, context: Context) {
        controller.render(lead: lead, rail: rail, fraction: fraction, burst: burst)
    }

    func sizeThatFits(
        _ proposal: ProposedViewSize,
        uiViewController: CompareContainerViewController,
        context: Context
    ) -> CGSize? {
        CGSize(width: proposal.width ?? 390, height: CompareContainerViewController.fittedHeight)
    }
}

struct DestinationRow: View {
    var title: String
    var symbol: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.s12) {
                Image(systemName: symbol)
                    .accessibilityHidden(true)
                    .frame(width: Spacing.s24)
                Text(title)
                    .font(TypeScale.font(.call))
                    .foregroundStyle(DesignTokens.ink)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.right")
                    .accessibilityHidden(true)
            }
        }
        .buttonStyle(BenchPressStyle(kind: .secondary))
        .accessibilityHint("Opens \(title)")
    }
}
