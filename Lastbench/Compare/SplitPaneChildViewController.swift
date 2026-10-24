import SwiftUI
import UIKit

/// One side of the split bench. The lead pane carries the hero figure.
/// The rail is a single row, not a second copy of the lead.
struct PaneFaceModel: Equatable {
    enum Role: Equatable {
        case lead
        case rail
    }

    var role: Role
    var nickname: String
    var costPerMile: Double
    var hasCost: Bool
    var distance: Double
    var mileCount: Int
    var ageDays: Int
    var band: EfficiencyBand
    var unit: DistanceUnit
    var paired: Bool

    static func unpaired(role: Role, unit: DistanceUnit) -> PaneFaceModel {
        PaneFaceModel(
            role: role,
            nickname: role == .lead ? "Left shoe" : "Right shoe",
            costPerMile: 0,
            hasCost: false,
            distance: 0,
            mileCount: 0,
            ageDays: 0,
            band: .insufficientData,
            unit: unit,
            paired: false
        )
    }

    static func reading(_ pane: ComparePresentation.PaneReading, role: Role, unit: DistanceUnit) -> PaneFaceModel {
        PaneFaceModel(
            role: role,
            nickname: pane.nickname,
            costPerMile: pane.costPerMile,
            hasCost: true,
            distance: pane.distance,
            mileCount: pane.mileCount,
            ageDays: pane.ageDays,
            band: pane.band,
            unit: unit,
            paired: true
        )
    }
}

struct PaneFace: View {
    var model: PaneFaceModel

    var body: some View {
        Group {
            if model.role == .lead {
                lead
            } else {
                rail
            }
        }
        .padding(Spacing.s12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var lead: some View {
        VStack(alignment: .leading, spacing: Spacing.s8) {
            Color.clear
                .frame(height: Spacing.s48)
                .accessibilityHidden(true)
            HStack(alignment: .firstTextBaseline, spacing: Spacing.s8) {
                Text(model.nickname)
                    .font(TypeScale.font(.title))
                    .foregroundStyle(DesignTokens.ink)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: Spacing.s8)
                GradeChip(band: model.band)
            }
            cost(TypeScale.font(.figure))
            HStack(spacing: Spacing.s8) {
                distanceText
                Text("·")
                    .foregroundStyle(DesignTokens.muted)
                    .accessibilityHidden(true)
                runText
            }
            .font(TypeScale.font(.body))
            .foregroundStyle(DesignTokens.ink)
            .fixedSize(horizontal: false, vertical: true)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private var rail: some View {
        HStack(alignment: .center, spacing: Spacing.s12) {
            VStack(alignment: .leading, spacing: Spacing.s4) {
                Text(model.nickname)
                    .font(TypeScale.font(.call))
                    .foregroundStyle(DesignTokens.ink)
                    .lineLimit(1)
                    .truncationMode(.tail)
                HStack(spacing: Spacing.s8) {
                    distanceText
                    runText
                }
                .font(TypeScale.font(.meta))
                .foregroundStyle(DesignTokens.muted)
            }
            Spacer(minLength: Spacing.s8)
            cost(TypeScale.font(.title))
                .layoutPriority(1)
        }
    }

    private func cost(_ font: Font) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s4) {
            if model.hasCost {
                Text(model.costPerMile, format: .currency(code: "USD").precision(.fractionLength(0...1)))
                    .font(font)
                    .foregroundStyle(DesignTokens.accent)
                    .monospacedDigit()
                    .contentTransition(.numericText(value: model.costPerMile))
                    .animation(Motion.press, value: model.costPerMile)
                    .fixedSize(horizontal: true, vertical: true)
                    .layoutPriority(1)
            } else {
                Text("unknown")
                    .font(font)
                    .foregroundStyle(DesignTokens.ink)
                    .fixedSize(horizontal: true, vertical: true)
            }
            Text("per mile")
                .font(TypeScale.font(.meta))
                .tracking(TypeScale.tracking(.meta))
                .foregroundStyle(DesignTokens.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }

    private var distanceText: some View {
        HStack(spacing: Spacing.s4) {
            if model.paired {
                Text(model.distance, format: .number.precision(.fractionLength(0...1)))
                    .contentTransition(.numericText(value: model.distance))
                    .animation(Motion.press, value: model.distance)
                Text(BenchCopy.unit(model.unit))
            } else {
                Text("unknown")
            }
        }
    }

    private var runText: some View {
        HStack(spacing: Spacing.s4) {
            Text(model.mileCount, format: .number.precision(.fractionLength(0)))
                .contentTransition(.numericText(value: Double(model.mileCount)))
                .animation(Motion.press, value: model.mileCount)
            Text("runs")
        }
    }
}

final class SplitPaneChildViewController: UIViewController {
    private var host: UIHostingController<PaneFace>?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(DesignTokens.surface)
        view.layer.cornerRadius = Radius.surface
        view.layer.borderWidth = Elevation.hairline
        view.layer.borderColor = UIColor(DesignTokens.muted).cgColor
        view.clipsToBounds = true
    }

    func apply(_ model: PaneFaceModel) {
        if let host {
            host.rootView = PaneFace(model: model)
            return
        }
        let host = UIHostingController(rootView: PaneFace(model: model))
        host.view.backgroundColor = .clear
        host.safeAreaRegions = []
        addChild(host)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(host.view)
        NSLayoutConstraint.activate([
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            host.view.topAnchor.constraint(equalTo: view.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        host.didMove(toParent: self)
        self.host = host
    }
}
