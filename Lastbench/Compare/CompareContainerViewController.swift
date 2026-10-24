import SpriteKit
import SwiftUI
import UIKit

/// Storyboard container for the locked split. Child panes stay mounted.
/// The tread scene is the one custom surface on this bench.
final class CompareContainerViewController: UIViewController {
    private var leftHost: UIView?
    private var rightHost: UIView?
    private var lead: SplitPaneChildViewController?
    private var rail: SplitPaneChildViewController?
    private var leftHeight: NSLayoutConstraint?
    private var railHeight: NSLayoutConstraint?
    private let treadView = SKView()
    private let tread = TreadAccentScene()
    private var appliedFraction: CGFloat = 0.68
    private var burstToken = 0

    /// Lead holds the tread strip plus nickname, amount, per-mile, distance, and runs.
    static let leadSlot: CGFloat = 300
    static let railSlot: CGFloat = 128
    static var fittedHeight: CGFloat { leadSlot + Spacing.s8 + railSlot }

    static func loadFromStoryboard() -> CompareContainerViewController {
        let board = UIStoryboard(name: "Compare", bundle: .main)
        if let controller = board.instantiateViewController(withIdentifier: "CompareContainer") as? CompareContainerViewController {
            return controller
        }
        return CompareContainerViewController(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(DesignTokens.bg)
        preferredContentSize = CGSize(width: 390, height: Self.fittedHeight)
        if children.isEmpty {
            embedProgrammaticChildren()
        }
        mapHosts()
        installTread()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard lead == nil else { return }
        let panes = children.compactMap { $0 as? SplitPaneChildViewController }
        lead = panes.first
        rail = panes.dropFirst().first
        if leftHost == nil {
            leftHost = lead?.view.superview
            rightHost = rail?.view.superview
        }
        if leftHeight == nil {
            installSplitConstraint()
        }
        if treadView.superview == nil {
            installTread()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tread.size = treadView.bounds.size
    }

    func render(lead: PaneFaceModel, rail: PaneFaceModel, fraction: CGFloat, burst: Int) {
        self.lead?.apply(lead)
        self.rail?.apply(rail)
        setFraction(fraction, animated: abs(fraction - appliedFraction) > 0.02 && abs(fraction - 0.68) < 0.001)
        if burst != burstToken {
            burstToken = burst
            if burst > 0 {
                tread.burst(reduceMotion: UIAccessibility.isReduceMotionEnabled)
            }
        }
    }

    private func mapHosts() {
        leftHost = view.subviews.first { $0.restorationIdentifier == "leftHost" }
        rightHost = view.subviews.first { $0.restorationIdentifier == "rightHost" }
        if let leftHost {
            lead = children.compactMap { $0 as? SplitPaneChildViewController }.first { $0.view.isDescendant(of: leftHost) }
        }
        if let rightHost {
            rail = children.compactMap { $0 as? SplitPaneChildViewController }.first { $0.view.isDescendant(of: rightHost) }
        }
        if leftHeight == nil {
            installSplitConstraint()
        }
    }

    private func installSplitConstraint() {
        guard let leftHost, let rightHost, leftHeight == nil else { return }
        for constraint in view.constraints where constraint.firstAttribute == .bottom || constraint.secondAttribute == .bottom {
            let hitsRail = constraint.firstItem as? UIView == rightHost || constraint.secondItem as? UIView == rightHost
            if hitsRail {
                constraint.priority = UILayoutPriority(250)
            }
        }
        let height = leftHost.heightAnchor.constraint(equalToConstant: Self.leadSlot)
        height.priority = .required
        height.isActive = true
        leftHeight = height
        let rail = rightHost.heightAnchor.constraint(equalToConstant: Self.railSlot)
        rail.priority = .required
        rail.isActive = true
        railHeight = rail
    }

    private func embedProgrammaticChildren() {
        let leftBox = UIView()
        let rightBox = UIView()
        leftBox.restorationIdentifier = "leftHost"
        rightBox.restorationIdentifier = "rightHost"
        leftBox.translatesAutoresizingMaskIntoConstraints = false
        rightBox.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(leftBox)
        view.addSubview(rightBox)
        let left = SplitPaneChildViewController()
        let right = SplitPaneChildViewController()
        embed(left, in: leftBox)
        embed(right, in: rightBox)
        NSLayoutConstraint.activate([
            leftBox.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            leftBox.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            leftBox.topAnchor.constraint(equalTo: view.topAnchor),
            rightBox.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            rightBox.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            rightBox.topAnchor.constraint(equalTo: leftBox.bottomAnchor, constant: Spacing.s8)
        ])
        let leadHeight = leftBox.heightAnchor.constraint(equalToConstant: Self.leadSlot)
        leadHeight.isActive = true
        leftHeight = leadHeight
        let railHeightConstraint = rightBox.heightAnchor.constraint(equalToConstant: Self.railSlot)
        railHeightConstraint.isActive = true
        railHeight = railHeightConstraint
        leftHost = leftBox
        rightHost = rightBox
        lead = left
        rail = right
    }

    private func embed(_ child: UIViewController, in box: UIView) {
        addChild(child)
        child.view.translatesAutoresizingMaskIntoConstraints = false
        box.addSubview(child.view)
        NSLayoutConstraint.activate([
            child.view.leadingAnchor.constraint(equalTo: box.leadingAnchor),
            child.view.trailingAnchor.constraint(equalTo: box.trailingAnchor),
            child.view.topAnchor.constraint(equalTo: box.topAnchor),
            child.view.bottomAnchor.constraint(equalTo: box.bottomAnchor)
        ])
        child.didMove(toParent: self)
    }

    private func installTread() {
        guard let leftHost else { return }
        tread.scaleMode = .resizeFill
        tread.backgroundColor = .clear
        treadView.presentScene(tread)
        treadView.allowsTransparency = true
        treadView.backgroundColor = .clear
        treadView.isUserInteractionEnabled = false
        treadView.accessibilityElementsHidden = true
        treadView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(treadView)
        NSLayoutConstraint.activate([
            treadView.leadingAnchor.constraint(equalTo: leftHost.leadingAnchor),
            treadView.trailingAnchor.constraint(equalTo: leftHost.trailingAnchor),
            treadView.topAnchor.constraint(equalTo: leftHost.topAnchor),
            treadView.heightAnchor.constraint(equalToConstant: Spacing.s48)
        ])
    }

    private func setFraction(_ fraction: CGFloat, animated: Bool) {
        guard leftHost != nil else { return }
        let clamped = min(0.84, max(0.42, fraction))
        guard abs(clamped - appliedFraction) > 0.004 else { return }
        appliedFraction = clamped
        let lead = max(Self.leadSlot, view.bounds.height * clamped)
        leftHeight?.constant = lead
        let updates = { self.view.layoutIfNeeded() }
        if animated, !UIAccessibility.isReduceMotionEnabled {
            UIView.animate(withDuration: 0.16, delay: 0, options: [.curveEaseOut, .allowUserInteraction], animations: updates)
        } else if animated {
            UIView.transition(with: view, duration: 0.16, options: .transitionCrossDissolve, animations: updates)
        } else {
            updates()
        }
    }
}
