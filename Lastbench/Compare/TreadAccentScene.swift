import SpriteKit
import SwiftUI

/// Sole custom-drawn surface. Geometric tread bursts when a mile commits.
/// Every other screen stays on stock controls.
final class TreadAccentScene: SKScene {
    func burst(reduceMotion: Bool) {
        removeAllChildren()
        removeAllActions()
        let tint = UIColor(DesignTokens.accent)
        if reduceMotion {
            let node = SKSpriteNode(texture: Self.dot(tint))
            node.alpha = 0
            node.position = CGPoint(x: size.width / 2, y: size.height / 2)
            node.size = CGSize(width: Spacing.s8, height: Spacing.s8)
            addChild(node)
            node.run(.fadeAlpha(to: 1, duration: 0.16))
            return
        }
        let emitter = SKEmitterNode()
        emitter.particleTexture = Self.dot(tint)
        emitter.particleBirthRate = 90
        emitter.numParticlesToEmit = 28
        emitter.particleLifetime = 0.45
        emitter.particleSpeed = 70
        emitter.particleSpeedRange = 36
        emitter.emissionAngleRange = .pi * 2
        emitter.particleScale = 0.35
        emitter.particleScaleRange = 0.15
        emitter.particleColor = tint
        emitter.particleColorBlendFactor = 1
        emitter.particleAlphaSpeed = -2.2
        emitter.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(emitter)
    }

    private static func dot(_ color: UIColor) -> SKTexture {
        let side = Spacing.s8
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: side, height: side))
        let image = renderer.image { context in
            color.setFill()
            context.cgContext.fillEllipse(in: CGRect(x: 0, y: 0, width: side, height: side))
        }
        return SKTexture(image: image)
    }
}
