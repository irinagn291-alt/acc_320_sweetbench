import Foundation

/// Refusal record. A second Match while the bench is already Matched
/// writes a JamMark and leaves the active pair in place.
struct JamMark: Codable, Equatable, Sendable, Identifiable {
    var id: UUID
    var loggedAt: Date

    init(id: UUID = UUID(), loggedAt: Date) {
        self.id = id
        self.loggedAt = loggedAt
    }
}
