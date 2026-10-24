import Foundation

/// Pairing of two lasts into the split compare panes.
/// Writing one folds the bench from Open to Matched.
struct MatchMark: Codable, Equatable, Sendable, Identifiable {
    var id: UUID
    var leftLastID: UUID
    var rightLastID: UUID
    var loggedAt: Date

    init(id: UUID = UUID(), leftLastID: UUID, rightLastID: UUID, loggedAt: Date) {
        self.id = id
        self.leftLastID = leftLastID
        self.rightLastID = rightLastID
        self.loggedAt = loggedAt
    }
}
