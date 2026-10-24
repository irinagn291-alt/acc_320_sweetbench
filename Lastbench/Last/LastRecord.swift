import Foundation

/// Owned pair on the bench. Purchase price and disposal value are inputs.
/// Cost-per-mile is computed from mile marks, never stored.
struct LastRecord: Codable, Equatable, Sendable, Identifiable {
    var id: UUID
    var nickname: String
    var purchasePrice: Double
    var disposalValue: Double
    var acquiredAt: Date
    var retiredAt: Date?

    init(
        id: UUID = UUID(),
        nickname: String,
        purchasePrice: Double,
        disposalValue: Double = 0,
        acquiredAt: Date,
        retiredAt: Date? = nil
    ) {
        self.id = id
        self.nickname = nickname
        self.purchasePrice = purchasePrice
        self.disposalValue = disposalValue
        self.acquiredAt = acquiredAt
        self.retiredAt = retiredAt
    }
}
