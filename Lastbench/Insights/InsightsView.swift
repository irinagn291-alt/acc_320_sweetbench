import SwiftUI

/// Ranks the closet by cost per mile. Grades are relative to these shoes.
struct InsightsView: View {
    @ObservedObject var session: CompareBenchSession
    @State private var reloading = false

    private var ranked: [ComparePresentation.ShelfReading] {
        session.presentation.shelf.sorted { lhs, rhs in
            let left = lhs.costPerMile ?? .greatestFiniteMagnitude
            let right = rhs.costPerMile ?? .greatestFiniteMagnitude
            if left == right { return lhs.nickname < rhs.nickname }
            return left < right
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.s16) {
                    if let note = session.presentation.loadNote {
                        failure(note)
                    }
                    Text("Grades are relative to this closet.")
                        .font(TypeScale.font(.body))
                        .foregroundStyle(DesignTokens.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    if ranked.isEmpty {
                        FullEmpty(
                            image: "lsb_EmptyRotationCutout",
                            title: "No ranks yet.",
                            line: "Add a shoe you own.",
                            actionTitle: "Retry"
                        ) {
                            reload()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    } else if let best = ranked.first {
                        hero(best)
                        VStack(spacing: Spacing.s8) {
                            ForEach(Array(ranked.dropFirst())) { row in
                                rankRow(row)
                            }
                        }
                        .padding(Spacing.s12)
                        .surfacePlate()
                    }
                }
                .padding(Spacing.s16)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(DesignTokens.bg)
            .navigationTitle("Ranks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    CloseControl()
                }
            }
        }
        .tint(DesignTokens.ink)
    }

    private func hero(_ row: ComparePresentation.ShelfReading) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s8) {
            Text("Lowest cost")
                .font(TypeScale.font(.meta))
                .tracking(TypeScale.tracking(.meta))
                .textCase(.uppercase)
                .foregroundStyle(DesignTokens.muted)
            Text(row.nickname)
                .font(TypeScale.font(.title))
                .foregroundStyle(DesignTokens.ink)
                .lineLimit(1)
                .truncationMode(.tail)
            if let cost = row.costPerMile {
                Text(cost, format: .currency(code: "USD").precision(.fractionLength(0...1)))
                    .font(TypeScale.font(.figure))
                    .foregroundStyle(DesignTokens.accent)
                    .monospacedDigit()
                    .contentTransition(.numericText(value: cost))
                    .animation(Motion.press, value: cost)
                    .fixedSize(horizontal: true, vertical: true)
            } else {
                Text("unknown")
                    .font(TypeScale.font(.figure))
                    .foregroundStyle(DesignTokens.ink)
            }
            Text("per mile")
                .font(TypeScale.font(.meta))
                .foregroundStyle(DesignTokens.muted)
            GradeChip(band: row.band)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.s16)
        .surfacePlate()
    }

    private func rankRow(_ row: ComparePresentation.ShelfReading) -> some View {
        HStack(spacing: Spacing.s8) {
            Text(row.nickname)
                .font(TypeScale.font(.call))
                .foregroundStyle(DesignTokens.ink)
                .lineLimit(1)
                .truncationMode(.tail)
            GradeChip(band: row.band)
            Spacer(minLength: Spacing.s8)
            if let cost = row.costPerMile {
                Text(cost, format: .currency(code: "USD").precision(.fractionLength(0...1)))
                    .font(TypeScale.font(.call))
                    .foregroundStyle(DesignTokens.ink)
                    .monospacedDigit()
                    .layoutPriority(1)
            } else {
                Text("unknown")
                    .font(TypeScale.font(.call))
                    .foregroundStyle(DesignTokens.ink)
            }
        }
        .frame(minHeight: Hit.min)
    }

    private func failure(_ note: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s8) {
            Text("Ranks failed. Try again.")
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
