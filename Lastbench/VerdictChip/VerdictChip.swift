import Foundation

/// Filed when both lasts in the active pair have at least four mile marks
/// and fourteen days of age. Names the lower cost-per-mile last.
struct VerdictChip: Codable, Equatable, Sendable, Identifiable {
    var id: UUID
    var lowerLastID: UUID
    var higherLastID: UUID
    var lowerCostPerMile: Double
    var higherCostPerMile: Double
    var filedAt: Date

    init(
        id: UUID = UUID(),
        lowerLastID: UUID,
        higherLastID: UUID,
        lowerCostPerMile: Double,
        higherCostPerMile: Double,
        filedAt: Date
    ) {
        self.id = id
        self.lowerLastID = lowerLastID
        self.higherLastID = higherLastID
        self.lowerCostPerMile = lowerCostPerMile
        self.higherCostPerMile = higherCostPerMile
        self.filedAt = filedAt
    }
}
