import Foundation

/// Refusal record. Mile while the bench is Open (or Bare) writes a SkidMark
/// and does not append a MileMark.
struct SkidMark: Codable, Equatable, Sendable, Identifiable {
    var id: UUID
    var loggedAt: Date

    init(id: UUID = UUID(), loggedAt: Date) {
        self.id = id
        self.loggedAt = loggedAt
    }
}
