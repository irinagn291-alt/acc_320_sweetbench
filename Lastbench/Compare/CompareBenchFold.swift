import Foundation

/// Pure Match ADT fold. Every mark is decided here. Screens and the store
/// apply the returned record. They do not branch on phase themselves.
enum CompareBenchFold {
    static func adoptLast(_ record: CompareRootRecord, last: LastRecord, now: Date) -> CompareRootRecord {
        var next = record
        next.lasts.append(last)
        if next.matchMarks.isEmpty {
            next.phase = .open
        } else {
            next.phase = phaseAfterMarks(next, now: now)
        }
        return next
    }

    static func match(
        _ record: CompareRootRecord,
        leftLastID: UUID,
        rightLastID: UUID,
        now: Date
    ) -> FoldOutcome {
        if record.lasts.isEmpty {
            var next = record
            next.phase = .bare
            return FoldOutcome(record: next, refusal: .needTwoLasts)
        }
        let phase = visiblePhase(record, now: now)
        if phase == .matched || phase == .divided {
            var next = record
            next.jamMarks.append(JamMark(loggedAt: now))
            next.phase = phase
            return FoldOutcome(record: next, refusal: .matchWhileMatched)
        }
        guard leftLastID != rightLastID,
              record.lasts.contains(where: { $0.id == leftLastID }),
              record.lasts.contains(where: { $0.id == rightLastID })
        else {
            return FoldOutcome(record: record, refusal: .needTwoLasts)
        }
        var next = record
        next.matchMarks.append(
            MatchMark(leftLastID: leftLastID, rightLastID: rightLastID, loggedAt: now)
        )
        next.phase = .matched
        return fileVerdictIfNeeded(next, now: now)
    }

    static func mile(
        _ record: CompareRootRecord,
        lastID: UUID,
        distance: Double,
        now: Date
    ) -> FoldOutcome {
        let phase = visiblePhase(record, now: now)
        if phase == .bare || phase == .open {
            var next = record
            next.skidMarks.append(SkidMark(loggedAt: now))
            next.phase = phase
            return FoldOutcome(record: next, refusal: .mileOnOpen)
        }
        guard distance > 0, distance.isFinite else {
            return FoldOutcome(record: record, refusal: .invalidDistance)
        }
        guard let pair = record.matchMarks.last,
              lastID == pair.leftLastID || lastID == pair.rightLastID
        else {
            return FoldOutcome(record: record, refusal: .lastNotInPair)
        }
        var next = record
        next.mileMarks.append(MileMark(lastID: lastID, distance: distance, loggedAt: now))
        next.phase = .matched
        return fileVerdictIfNeeded(next, now: now)
    }

    static func peel(_ record: CompareRootRecord, now: Date) -> FoldOutcome {
        guard let latest = record.mileMarks.max(by: { $0.loggedAt < $1.loggedAt }) else {
            return FoldOutcome(record: record, refusal: .nothingToPeel)
        }
        var next = record
        next.mileMarks.removeAll { $0.id == latest.id }
        next.peelMarks.append(PeelMark(droppedMileID: latest.id, loggedAt: now))
        next.phase = phaseAfterMarks(next, now: now)
        return FoldOutcome(record: next, refusal: nil)
    }

    static func visiblePhase(_ record: CompareRootRecord, now: Date) -> CompareBenchPhase {
        if record.lasts.isEmpty { return .bare }
        guard record.matchMarks.last != nil else { return .open }
        if pairQualifies(record, now: now) { return .divided }
        return .matched
    }

    static func costPerMile(in record: CompareRootRecord, lastID: UUID) -> Double? {
        guard let last = record.lasts.first(where: { $0.id == lastID }) else { return nil }
        let miles = RotationEfficiency.totalDistance(record.mileMarks, lastID: lastID)
        return RotationEfficiency.costPerMile(
            price: last.purchasePrice,
            disposal: last.disposalValue,
            miles: miles
        )
    }

    /// Five-pair simulator rotation. Left last already has miles so Mile is live.
    /// Neither side has four marks, so the bench stays Matched.
    static func demoRotation(now: Date, calendar: Calendar = .current) -> CompareRootRecord {
        let day = calendar.date(byAdding: .day, value: -21, to: now) ?? now
        let names = ["Track", "Trail", "Tempo", "Easy", "Race"]
        let prices = [160.0, 140.0, 180.0, 90.0, 220.0]
        var lasts: [LastRecord] = []
        for index in 0..<5 {
            let acquired = calendar.date(byAdding: .day, value: -index, to: day) ?? day
            lasts.append(
                LastRecord(
                    nickname: names[index],
                    purchasePrice: prices[index],
                    disposalValue: 0,
                    acquiredAt: acquired
                )
            )
        }
        var record = CompareRootRecord.empty
        record.lasts = lasts
        record.onboardingComplete = true
        record.mileMarks = [
            MileMark(lastID: lasts[0].id, distance: 6.2, loggedAt: calendar.date(byAdding: .day, value: -3, to: now) ?? now),
            MileMark(lastID: lasts[0].id, distance: 4.0, loggedAt: calendar.date(byAdding: .day, value: -1, to: now) ?? now),
            MileMark(lastID: lasts[1].id, distance: 5.0, loggedAt: calendar.date(byAdding: .day, value: -2, to: now) ?? now),
            MileMark(lastID: lasts[2].id, distance: 8.0, loggedAt: calendar.date(byAdding: .day, value: -4, to: now) ?? now),
            MileMark(lastID: lasts[3].id, distance: 3.5, loggedAt: calendar.date(byAdding: .day, value: -5, to: now) ?? now),
            MileMark(lastID: lasts[4].id, distance: 10.0, loggedAt: calendar.date(byAdding: .day, value: -6, to: now) ?? now)
        ]
        record.matchMarks = [
            MatchMark(leftLastID: lasts[0].id, rightLastID: lasts[1].id, loggedAt: now)
        ]
        record.phase = .matched
        return record
    }

    private static func phaseAfterMarks(_ record: CompareRootRecord, now: Date) -> CompareBenchPhase {
        if record.lasts.isEmpty { return .bare }
        guard record.matchMarks.last != nil else { return .open }
        return pairQualifies(record, now: now) ? .divided : .matched
    }

    private static func pairQualifies(_ record: CompareRootRecord, now: Date) -> Bool {
        guard let pair = record.matchMarks.last,
              let left = record.lasts.first(where: { $0.id == pair.leftLastID }),
              let right = record.lasts.first(where: { $0.id == pair.rightLastID })
        else { return false }
        return qualifies(left, marks: record.mileMarks, now: now)
            && qualifies(right, marks: record.mileMarks, now: now)
    }

    private static func qualifies(_ last: LastRecord, marks: [MileMark], now: Date) -> Bool {
        RotationEfficiency.mileCount(marks, lastID: last.id) >= RotationEfficiency.verdictMileCount
            && RotationEfficiency.ageDays(from: last.acquiredAt, to: now) >= RotationEfficiency.verdictAgeDays
    }

    private static func fileVerdictIfNeeded(_ record: CompareRootRecord, now: Date) -> FoldOutcome {
        guard pairQualifies(record, now: now),
              let pair = record.matchMarks.last,
              let left = record.lasts.first(where: { $0.id == pair.leftLastID }),
              let right = record.lasts.first(where: { $0.id == pair.rightLastID }),
              let leftCost = costPerMile(in: record, lastID: left.id),
              let rightCost = costPerMile(in: record, lastID: right.id)
        else {
            var held = record
            held.phase = record.matchMarks.isEmpty ? visiblePhase(record, now: now) : .matched
            return FoldOutcome(record: held, refusal: nil)
        }
        var next = record
        let leftWins = leftCost <= rightCost
        let alreadyFiled = next.verdictChips.contains { chip in
            chip.lowerLastID == (leftWins ? left.id : right.id)
                && chip.higherLastID == (leftWins ? right.id : left.id)
        }
        if !alreadyFiled {
            next.verdictChips.append(
                VerdictChip(
                    lowerLastID: leftWins ? left.id : right.id,
                    higherLastID: leftWins ? right.id : left.id,
                    lowerCostPerMile: min(leftCost, rightCost),
                    higherCostPerMile: max(leftCost, rightCost),
                    filedAt: now
                )
            )
        }
        next.phase = .divided
        return FoldOutcome(record: next, refusal: nil)
    }
}

/// Result of one fold step. A refusal means the command did not apply,
/// except SkidMark and JamMark which are themselves the written consequence.
struct FoldOutcome: Equatable, Sendable {
    var record: CompareRootRecord
    var refusal: BenchRefusal?
}

enum BenchRefusal: String, Equatable, Sendable {
    case mileOnOpen
    case matchWhileMatched
    case invalidDistance
    case lastNotInPair
    case needTwoLasts
    case nothingToPeel
}
