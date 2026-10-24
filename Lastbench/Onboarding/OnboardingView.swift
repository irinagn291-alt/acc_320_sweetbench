import SwiftUI

/// Three pages. Skip and Start both mark the introduction done.
struct OnboardingView: View {
    @ObservedObject var session: CompareBenchSession
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var page = 0

    private let pages: [(image: String, word: String, line: String)] = [
        ("lsb_Onboarding1", "Pairs", "Log miles on shoes you own. See what each pair costs per mile."),
        ("lsb_Onboarding2", "Mile", "Pair two shoes, then log the distance from today's run."),
        ("lsb_Onboarding3", "Split", "After four runs and fourteen days on both shoes, the bench names the cheaper pair.")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s16) {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.s16) {
                    Image(pages[page].image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: Spacing.s48 * 5)
                        .clipped()
                        .background(DesignTokens.surface)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.surface))
                        .accessibilityHidden(true)
                    Group {
                        if dynamicTypeSize.isAccessibilitySize {
                            Text(pages[page].word)
                                .font(TypeScale.font(.title))
                        } else {
                            Text(pages[page].word)
                                .font(TypeScale.font(.display))
                                .tracking(TypeScale.tracking(.display))
                        }
                    }
                    .textCase(.uppercase)
                    .foregroundStyle(DesignTokens.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                    Text(pages[page].line)
                        .font(TypeScale.font(.body))
                        .foregroundStyle(DesignTokens.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(Spacing.s16)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            VStack(spacing: Spacing.s8) {
                Button {
                    session.finishOnboarding()
                } label: {
                    Text("Skip")
                }
                .buttonStyle(BenchPressStyle(kind: .secondary))
                Button {
                    if page < pages.count - 1 {
                        page += 1
                    } else {
                        session.finishOnboarding()
                    }
                } label: {
                    Text(page < pages.count - 1 ? "Next" : "Start")
                }
                .buttonStyle(BenchPressStyle(kind: .primary))
            }
            .padding(.horizontal, Spacing.s16)
            .padding(.bottom, Spacing.s16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(DesignTokens.bg)
        .accessibilityElement(children: .contain)
    }
}
