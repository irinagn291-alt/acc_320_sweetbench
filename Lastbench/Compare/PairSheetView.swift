import SwiftUI

/// Chooses the two shoes that sit on the bench.
struct PairSheetView: View {
    @ObservedObject var session: CompareBenchSession
    @Environment(\.dismiss) private var dismiss
    @State private var leftPick: UUID?
    @State private var rightPick: UUID?
    @State private var commits = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.s16) {
                    Text("Pair")
                        .font(TypeScale.font(.title))
                        .foregroundStyle(DesignTokens.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(status)
                        .font(TypeScale.font(.body))
                        .foregroundStyle(DesignTokens.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    if session.presentation.shelf.count < 2 {
                        FullEmpty(
                            image: "lsb_EmptyRotationCutout",
                            title: "Need two shoes.",
                            line: "Add a shoe you own.",
                            actionTitle: "Close"
                        ) {
                            dismiss()
                        }
                    } else {
                        shoeList(side: .left)
                        shoeList(side: .right)
                        Button {
                            filePair()
                        } label: {
                            Text("Pair these")
                        }
                        .buttonStyle(BenchPressStyle(kind: .primary))
                        .disabled(!canPairFresh)
                        if session.presentation.phase == .matched || session.presentation.phase == .divided {
                            Button {
                                filePair()
                            } label: {
                                Text("Pair again")
                            }
                            .buttonStyle(BenchPressStyle(kind: .secondary))
                            .disabled(leftPick == nil || rightPick == nil || leftPick == rightPick)
                        }
                    }
                }
                .padding(Spacing.s16)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(DesignTokens.bg)
            .navigationTitle("Pair shoes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    CloseControl()
                }
            }
        }
        .tint(DesignTokens.ink)
        .sensoryFeedback(.impact(weight: .medium), trigger: commits)
        .onAppear {
            if leftPick == nil {
                leftPick = session.presentation.left?.id
            }
            if rightPick == nil {
                rightPick = session.presentation.right?.id
            }
        }
    }

    private enum Side {
        case left
        case right
    }

    private var canPairFresh: Bool {
        guard let leftPick, let rightPick, leftPick != rightPick else { return false }
        return session.presentation.phase == .bare || session.presentation.phase == .open
    }

    private var status: String {
        if let refusal = BenchCopy.refusal(session.presentation.refusal) {
            return refusal
        }
        switch session.presentation.phase {
        case .bare, .open:
            return "Choose two shoes. Then log miles."
        case .matched, .divided:
            return "Bench already paired."
        }
    }

    private func shoeList(side: Side) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s8) {
            Text(side == .left ? "Left shoe" : "Right shoe")
                .font(TypeScale.font(.meta))
                .tracking(TypeScale.tracking(.meta))
                .textCase(.uppercase)
                .foregroundStyle(DesignTokens.muted)
            ForEach(session.presentation.shelf) { shoe in
                let selected = (side == .left ? leftPick : rightPick) == shoe.id
                Button {
                    if side == .left {
                        leftPick = shoe.id
                    } else {
                        rightPick = shoe.id
                    }
                } label: {
                    HStack(spacing: Spacing.s8) {
                        Text(shoe.nickname)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Spacer(minLength: Spacing.s8)
                        Text(selected ? "Selected" : "Choose")
                            .font(TypeScale.font(.meta))
                    }
                }
                .buttonStyle(BenchPressStyle(kind: selected ? .primary : .secondary))
                .accessibilityLabel("\(shoe.nickname), \(selected ? "selected" : "not selected")")
            }
        }
    }

    private func filePair() {
        guard let leftPick, let rightPick else { return }
        let before = session.presentation.pairings.count
        session.match(leftLastID: leftPick, rightLastID: rightPick)
        if session.presentation.refusal == nil, session.presentation.pairings.count > before {
            commits += 1
            dismiss()
        }
    }
}
