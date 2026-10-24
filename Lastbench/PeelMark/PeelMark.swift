import Foundation

/// Undo record. Peel drops the latest MileMark and keeps this receipt.
struct PeelMark: Codable, Equatable, Sendable, Identifiable {
    var id: UUID
    var droppedMileID: UUID
    var loggedAt: Date

    init(id: UUID = UUID(), droppedMileID: UUID, loggedAt: Date) {
        self.id = id
        self.droppedMileID = droppedMileID
        self.loggedAt = loggedAt
    }
}
