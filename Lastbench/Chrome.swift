import SwiftUI

/// Spacing, type, radius, and motion for the compare chrome.
/// Colours stay in `DesignTokens`. Every pad is one of these steps.
enum BenchCover: String, Identifiable {
    case library
    case ledger
    case insights
    case settings
    case pair
    case twist

    var id: String { rawValue }
}

enum Spacing {
    static let s4: CGFloat = 4
    static let s8: CGFloat = 8
    static let s12: CGFloat = 12
    static let s16: CGFloat = 16
    static let s20: CGFloat = 20
    static let s24: CGFloat = 24
    static let s32: CGFloat = 32
    static let s40: CGFloat = 40
    static let s48: CGFloat = 48
}

enum Hit {
    static let min: CGFloat = 44
}

enum Radius {
    static let surface: CGFloat = 4
    static let chip: CGFloat = 2
}

enum Elevation {
    static let hairline: CGFloat = 1
}

enum Motion {
    static let press = Animation.easeOut(duration: 0.16)
    static let scaleDown: CGFloat = 0.97
    static let sheetScale: CGFloat = 0.96
}

enum TypeStep {
    case display
    case title
    case body
    case figure
    case call
    case meta
}

enum TypeScale {
    static func font(_ step: TypeStep) -> Font {
        switch step {
        case .display:
            Font.custom(DesignTokens.fontFamily, size: 64, relativeTo: .largeTitle).weight(.medium)
        case .title:
            Font.custom(DesignTokens.fontFamily, size: 28, relativeTo: .title).weight(.medium)
        case .body:
            Font.custom(DesignTokens.fontFamily, size: 17, relativeTo: .body)
        case .figure:
            Font.custom(DesignTokens.fontFamily, size: 44, relativeTo: .largeTitle).weight(.medium).monospacedDigit()
        case .call:
            Font.custom(DesignTokens.fontFamily, size: 17, relativeTo: .headline).weight(.medium)
        case .meta:
            Font.custom(DesignTokens.fontFamily, size: 13, relativeTo: .caption).weight(.medium)
        }
    }

    static func tracking(_ step: TypeStep) -> CGFloat {
        switch step {
        case .display:
            -0.5
        case .meta:
            1
        default:
            0
        }
    }
}

enum BenchCopy {
    static func refusal(_ refusal: BenchRefusal?) -> String? {
        switch refusal {
        case nil:
            nil
        case .mileOnOpen:
            "Mile refused. Pair two shoes first."
        case .matchWhileMatched:
            "Pair refused. Bench already paired."
        case .invalidDistance:
            "Distance refused. Enter a number above zero."
        case .lastNotInPair:
            "Mile refused. That shoe is outside the pair."
        case .needTwoLasts:
            "Pair refused. Add two shoes first."
        case .nothingToPeel:
            "Undo refused. No outing to remove."
        }
    }

    static func phase(_ phase: CompareBenchPhase) -> String {
        switch phase {
        case .bare:
            "Closet empty. Add a shoe you own."
        case .open:
            "Unpaired. Pair two shoes, then log a mile."
        case .matched:
            "Paired. Log today's distance on the left shoe."
        case .divided:
            "Split filed. The cheaper shoe is named."
        }
    }

    static func band(_ band: EfficiencyBand) -> String {
        switch band {
        case .insufficientData:
            "Need peers"
        case .aPlus:
            "A+"
        case .a:
            "A"
        case .b:
            "B"
        case .c:
            "C"
        case .d:
            "D"
        case .f:
            "F"
        }
    }

    static func unit(_ unit: DistanceUnit) -> String {
        switch unit {
        case .miles:
            "mi"
        case .kilometres:
            "km"
        }
    }
}

enum DecimalInput {
    static func amount(from text: String) -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !trimmed.contains("-") else { return nil }
        let style = Decimal.FormatStyle(locale: .current)
        guard let decimal = try? Decimal(trimmed, format: style) else { return nil }
        let number = NSDecimalNumber(decimal: decimal).doubleValue
        guard number.isFinite, number >= 0 else { return nil }
        return number
    }

    static func distance(from text: String) -> Double? {
        guard let number = amount(from: text), number > 0 else { return nil }
        return number
    }
}

struct SurfacePlate: ViewModifier {
    var chip: Bool = false

    func body(content: Content) -> some View {
        let radius = chip ? Radius.chip : Radius.surface
        content
            .background {
                RoundedRectangle(cornerRadius: radius)
                    .fill(DesignTokens.surface)
            }
            .overlay {
                RoundedRectangle(cornerRadius: radius)
                    .strokeBorder(DesignTokens.muted, lineWidth: Elevation.hairline)
            }
    }
}

extension View {
    func surfacePlate(chip: Bool = false) -> some View {
        modifier(SurfacePlate(chip: chip))
    }
}

struct BenchPressStyle: ButtonStyle {
    enum Kind {
        case primary
        case secondary
        case destructive
    }

    var kind: Kind = .primary
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        let border: Color = {
            switch kind {
            case .primary:
                DesignTokens.bg
            case .secondary:
                DesignTokens.muted
            case .destructive:
                DesignTokens.ink
            }
        }()
        let fill: Color = {
            if kind == .primary && isEnabled {
                return DesignTokens.accent
            }
            return DesignTokens.surface
        }()
        let ink: Color = {
            if kind == .primary {
                return isEnabled ? DesignTokens.bg : DesignTokens.muted
            }
            return isEnabled ? DesignTokens.ink : DesignTokens.muted
        }()
        let pressedOpacity = configuration.isPressed && reduceMotion ? 0.72 : 1.0
        let enabledOpacity = isEnabled ? 1.0 : 0.45

        configuration.label
            .font(TypeScale.font(.call))
            .foregroundStyle(ink)
            .frame(maxWidth: .infinity, minHeight: Hit.min)
            .padding(.horizontal, Spacing.s16)
            .padding(.vertical, Spacing.s8)
            .background {
                RoundedRectangle(cornerRadius: Radius.surface)
                    .fill(fill)
            }
            .overlay {
                RoundedRectangle(cornerRadius: Radius.surface)
                    .strokeBorder(border, lineWidth: Elevation.hairline)
            }
            .contentShape(RoundedRectangle(cornerRadius: Radius.surface))
            .scaleEffect(!reduceMotion && configuration.isPressed ? Motion.scaleDown : 1)
            .opacity(pressedOpacity * enabledOpacity)
            .animation(Motion.press, value: configuration.isPressed)
    }
}

struct SheetEntrance: ViewModifier {
    var plays = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(!plays || reduceMotion ? 1 : (shown ? 1 : Motion.sheetScale))
            .opacity(!plays || shown ? 1 : 0)
            .onAppear {
                guard plays else {
                    shown = true
                    return
                }
                withAnimation(Motion.press) {
                    shown = true
                }
            }
    }
}

struct CloseControl: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Button {
            dismiss()
        } label: {
            HStack(spacing: Spacing.s8) {
                Image(systemName: "xmark")
                Text("Close")
            }
            .frame(minWidth: Hit.min, minHeight: Hit.min)
            .contentShape(Rectangle())
        }
        .accessibilityLabel("Close")
    }
}

struct GradeChip: View {
    var band: EfficiencyBand

    var body: some View {
        HStack(spacing: Spacing.s4) {
            Image(systemName: band == .insufficientData ? "circle.dashed" : "seal")
                .accessibilityHidden(true)
            Text(BenchCopy.band(band))
                .font(TypeScale.font(.meta))
                .tracking(TypeScale.tracking(.meta))
        }
        .foregroundStyle(DesignTokens.ink)
        .padding(.horizontal, Spacing.s8)
        .padding(.vertical, Spacing.s4)
        .surfacePlate(chip: true)
        .accessibilityLabel("Grade \(BenchCopy.band(band))")
    }
}
