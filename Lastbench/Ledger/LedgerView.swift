import SwiftUI

/// Outing history for the rotation, plus undo of the newest mile.
struct LedgerView: View {
    @ObservedObject var session: CompareBenchSession
    @Environment(\.dismiss) private var dismiss
    @State private var reloading = false

    var body: some View {
        NavigationStack {
            Group {
                if session.presentation.outings.isEmpty && session.presentation.pairings.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.s16) {
                        if let note = session.presentation.loadNote {
                            noteBlock(note)
                        }
                        FullEmpty(
                            image: "lsb_EmptyHome",
                            title: "No outings yet.",
                            line: "Log a mile on the bench.",
                            actionTitle: "Close"
                        ) {
                            dismiss()
                        }
                    }
                    .padding(Spacing.s16)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                } else {
                    populatedScroll
                }
            }
            .background(DesignTokens.bg)
            .navigationTitle("Outings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    CloseControl()
                }
            }
        }
        .tint(DesignTokens.ink)
    }

    private var populatedScroll: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s16) {
                if let note = session.presentation.loadNote {
                    noteBlock(note)
                }
                if let newest = session.presentation.outings.first {
                    hero(newest)
                    ForEach(Array(session.presentation.outings.dropFirst())) { outing in
                        compact(outing)
                    }
                }
                if !session.presentation.pairings.isEmpty {
                    pairingColumn
                }
                Button {
                    session.peel()
                } label: {
                    Text("Undo outing")
                }
                .buttonStyle(BenchPressStyle(kind: .secondary))
                .disabled(!session.presentation.canPeel || reloading)
            }
            .padding(Spacing.s16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func hero(_ outing: ComparePresentation.OutingReading) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s8) {
            Text("Newest")
                .font(TypeScale.font(.meta))
                .tracking(TypeScale.tracking(.meta))
                .textCase(.uppercase)
                .foregroundStyle(DesignTokens.muted)
            HStack(spacing: Spacing.s8) {
                Text(outing.nickname)
                    .font(TypeScale.font(.title))
                    .foregroundStyle(DesignTokens.ink)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer(minLength: Spacing.s8)
                Text(outing.distance, format: .number.precision(.fractionLength(0...1)))
                    .font(TypeScale.font(.figure))
                    .foregroundStyle(DesignTokens.accent)
                    .monospacedDigit()
                    .contentTransition(.numericText(value: outing.distance))
                    .animation(Motion.press, value: outing.distance)
                    .layoutPriority(1)
                Text(BenchCopy.unit(session.presentation.distanceUnit))
                    .font(TypeScale.font(.meta))
                    .foregroundStyle(DesignTokens.muted)
            }
            Text(outing.loggedAt, format: .dateTime.month().day().hour().minute())
                .font(TypeScale.font(.body))
                .foregroundStyle(DesignTokens.ink)
        }
        .padding(Spacing.s16)
        .surfacePlate()
    }

    private func compact(_ outing: ComparePresentation.OutingReading) -> some View {
        HStack(spacing: Spacing.s12) {
            VStack(alignment: .leading, spacing: Spacing.s4) {
                Text(outing.nickname)
                    .font(TypeScale.font(.call))
                    .foregroundStyle(DesignTokens.ink)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text(outing.loggedAt, format: .dateTime.month().day().hour().minute())
                    .font(TypeScale.font(.meta))
                    .foregroundStyle(DesignTokens.muted)
            }
            Spacer(minLength: Spacing.s8)
            Text(outing.distance, format: .number.precision(.fractionLength(0...1)))
                .font(TypeScale.font(.call))
                .foregroundStyle(DesignTokens.ink)
                .monospacedDigit()
                .layoutPriority(1)
        }
        .padding(Spacing.s12)
        .surfacePlate()
    }

    private var pairingColumn: some View {
        VStack(alignment: .leading, spacing: Spacing.s8) {
            Text("Pairs filed")
                .font(TypeScale.font(.meta))
                .tracking(TypeScale.tracking(.meta))
                .textCase(.uppercase)
                .foregroundStyle(DesignTokens.muted)
            ForEach(session.presentation.pairings) { pair in
                HStack(spacing: Spacing.s8) {
                    Text(pair.leftName)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Text("+")
                        .foregroundStyle(DesignTokens.muted)
                        .accessibilityHidden(true)
                    Text(pair.rightName)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Spacer(minLength: Spacing.s8)
                }
                .font(TypeScale.font(.body))
                .foregroundStyle(DesignTokens.ink)
                .frame(minHeight: Hit.min)
            }
        }
        .padding(Spacing.s16)
        .surfacePlate()
    }

    private func noteBlock(_ note: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s8) {
            Text("Outings failed. Try again.")
                .font(TypeScale.font(.call))
                .foregroundStyle(DesignTokens.ink)
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
        .padding(Spacing.s16)
        .surfacePlate()
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
