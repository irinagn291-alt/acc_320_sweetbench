import Foundation

/// Relative efficiency for one last against the local rotation.
/// Grades exist only with five or more peers that are at least seven days old.
enum EfficiencyBand: String, Codable, Equatable, Sendable {
    case aPlus = "A+"
    case a = "A"
    case b = "B"
    case c = "C"
    case d = "D"
    case f = "F"
    case insufficientData
}

/// Family calculator. Cost-per-mile is (price − disposal) / max(distance, 1).
/// A lower figure is more efficient. The band is a percentile inside this library.
enum RotationEfficiency {
    static let peerFloor = 5
    static let gradeAgeDays = 7
    static let verdictMileCount = 4
    static let verdictAgeDays = 14

    static func costPerMile(price: Double, disposal: Double, miles: Double) -> Double {
        (price - disposal) / max(miles, 1)
    }

    static func ageDays(from acquiredAt: Date, to now: Date, calendar: Calendar = .current) -> Int {
        let start = calendar.startOfDay(for: acquiredAt)
        let end = calendar.startOfDay(for: now)
        return calendar.dateComponents([.day], from: start, to: end).day ?? 0
    }

    static func totalDistance(_ marks: [MileMark], lastID: UUID) -> Double {
        marks.reduce(0) { partial, mark in
            mark.lastID == lastID ? partial + mark.distance : partial
        }
    }

    static func mileCount(_ marks: [MileMark], lastID: UUID) -> Int {
        marks.reduce(0) { partial, mark in
            mark.lastID == lastID ? partial + 1 : partial
        }
    }

    static func band(
        for last: LastRecord,
        among lasts: [LastRecord],
        mileMarks: [MileMark],
        now: Date,
        calendar: Calendar = .current
    ) -> EfficiencyBand {
        let eligible = lasts.filter { candidate in
            ageDays(from: candidate.acquiredAt, to: now, calendar: calendar) >= gradeAgeDays
        }
        guard eligible.count >= peerFloor else { return .insufficientData }
        guard ageDays(from: last.acquiredAt, to: now, calendar: calendar) >= gradeAgeDays else {
            return .insufficientData
        }
        let mine = costPerMile(
            price: last.purchasePrice,
            disposal: last.disposalValue,
            miles: totalDistance(mileMarks, lastID: last.id)
        )
        let worse = eligible.reduce(0) { partial, peer in
            let peerCost = costPerMile(
                price: peer.purchasePrice,
                disposal: peer.disposalValue,
                miles: totalDistance(mileMarks, lastID: peer.id)
            )
            return peerCost > mine ? partial + 1 : partial
        }
        let percentile = Double(worse) / Double(eligible.count)
        switch percentile {
        case 0.80...:
            return .aPlus
        case 0.60..<0.80:
            return .a
        case 0.40..<0.60:
            return .b
        case 0.20..<0.40:
            return .c
        case 0.05..<0.20:
            return .d
        default:
            return .f
        }
    }
}
