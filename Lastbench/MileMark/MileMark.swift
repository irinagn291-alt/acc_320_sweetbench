import Foundation

/// One outing logged against a single last. Distance is the persisted fact.
/// The bench recomputes cost-per-mile from the set of marks.
struct MileMark: Codable, Equatable, Sendable, Identifiable {
    var id: UUID
    var lastID: UUID
    var distance: Double
    var loggedAt: Date

    init(id: UUID = UUID(), lastID: UUID, distance: Double, loggedAt: Date) {
        self.id = id
        self.lastID = lastID
        self.distance = distance
        self.loggedAt = loggedAt
    }
}
