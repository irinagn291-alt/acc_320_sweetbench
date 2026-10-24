import Foundation

/// Read model between the compare root and the split bench.
/// Figures are derived. The view paints this snapshot and sends commands back.
struct ComparePresentation: Equatable, Sendable {
    var phase: CompareBenchPhase
    var left: PaneReading?
    var right: PaneReading?
    var verdict: VerdictChip?
    var mileEnabled: Bool
    var refusal: BenchRefusal?
    var loadNote: String?
    var bands: [UUID: EfficiencyBand]
    var onboardingComplete: Bool
    var distanceUnit: DistanceUnit
    var shelf: [ShelfReading]
    var outings: [OutingReading]
    var pairings: [PairingReading]
    var canPeel: Bool

    struct PaneReading: Equatable, Sendable, Identifiable {
        var id: UUID
        var nickname: String
        var costPerMile: Double
        var distance: Double
        var mileCount: Int
        var ageDays: Int
        var band: EfficiencyBand
    }

    struct ShelfReading: Equatable, Sendable, Identifiable {
        var id: UUID
        var nickname: String
        var purchasePrice: Double
        var disposalValue: Double
        var ageDays: Int
        var band: EfficiencyBand
        var costPerMile: Double?
        var mileCount: Int
        var distance: Double
        var retired: Bool
    }

    struct OutingReading: Equatable, Sendable, Identifiable {
        var id: UUID
        var nickname: String
        var distance: Double
        var loggedAt: Date
    }

    struct PairingReading: Equatable, Sendable, Identifiable {
        var id: UUID
        var leftName: String
        var rightName: String
        var loggedAt: Date
    }

    static func make(
        record: CompareRootRecord,
        refusal: BenchRefusal? = nil,
        loadNote: String? = nil,
        now: Date
    ) -> ComparePresentation {
        let phase = CompareBenchFold.visiblePhase(record, now: now)
        var bands: [UUID: EfficiencyBand] = [:]
        for last in record.lasts {
            bands[last.id] = RotationEfficiency.band(
                for: last,
                among: record.lasts,
                mileMarks: record.mileMarks,
                now: now
            )
        }
        let pair = record.matchMarks.last
        let names = Dictionary(uniqueKeysWithValues: record.lasts.map { ($0.id, $0.nickname) })
        let shelf = record.lasts.map { last in
            ShelfReading(
                id: last.id,
                nickname: last.nickname,
                purchasePrice: last.purchasePrice,
                disposalValue: last.disposalValue,
                ageDays: RotationEfficiency.ageDays(from: last.acquiredAt, to: now),
                band: bands[last.id] ?? .insufficientData,
                costPerMile: CompareBenchFold.costPerMile(in: record, lastID: last.id),
                mileCount: RotationEfficiency.mileCount(record.mileMarks, lastID: last.id),
                distance: RotationEfficiency.totalDistance(record.mileMarks, lastID: last.id),
                retired: last.retiredAt != nil
            )
        }
        let outings = record.mileMarks.sorted { $0.loggedAt > $1.loggedAt }.map { mark in
            OutingReading(
                id: mark.id,
                nickname: names[mark.lastID] ?? "Unknown",
                distance: mark.distance,
                loggedAt: mark.loggedAt
            )
        }
        let pairings = record.matchMarks.map { mark in
            PairingReading(
                id: mark.id,
                leftName: names[mark.leftLastID] ?? "Unknown",
                rightName: names[mark.rightLastID] ?? "Unknown",
                loggedAt: mark.loggedAt
            )
        }
        return ComparePresentation(
            phase: phase,
            left: pane(record, id: pair?.leftLastID, bands: bands, now: now),
            right: pane(record, id: pair?.rightLastID, bands: bands, now: now),
            verdict: record.verdictChips.last,
            mileEnabled: phase == .matched || phase == .divided,
            refusal: refusal,
            loadNote: loadNote,
            bands: bands,
            onboardingComplete: record.onboardingComplete,
            distanceUnit: record.distanceUnit,
            shelf: shelf,
            outings: outings,
            pairings: pairings,
            canPeel: !record.mileMarks.isEmpty
        )
    }

    private static func pane(
        _ record: CompareRootRecord,
        id: UUID?,
        bands: [UUID: EfficiencyBand],
        now: Date
    ) -> PaneReading? {
        guard let id, let last = record.lasts.first(where: { $0.id == id }) else { return nil }
        return PaneReading(
            id: last.id,
            nickname: last.nickname,
            costPerMile: CompareBenchFold.costPerMile(in: record, lastID: last.id) ?? 0,
            distance: RotationEfficiency.totalDistance(record.mileMarks, lastID: last.id),
            mileCount: RotationEfficiency.mileCount(record.mileMarks, lastID: last.id),
            ageDays: RotationEfficiency.ageDays(from: last.acquiredAt, to: now),
            band: bands[last.id] ?? .insufficientData
        )
    }
}
