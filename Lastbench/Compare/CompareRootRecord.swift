import Foundation

/// Single persisted compare root. Lasts, marks, chips, settings, and the
/// current fold phase travel together under one schema version.
struct CompareRootRecord: Codable, Equatable, Sendable {
    var schemaVersion: Int
    var phase: CompareBenchPhase
    var lasts: [LastRecord]
    var matchMarks: [MatchMark]
    var mileMarks: [MileMark]
    var skidMarks: [SkidMark]
    var jamMarks: [JamMark]
    var peelMarks: [PeelMark]
    var verdictChips: [VerdictChip]
    var onboardingComplete: Bool
    var distanceUnit: DistanceUnit

    static let currentSchema = 1

    static var empty: CompareRootRecord {
        CompareRootRecord(
            schemaVersion: currentSchema,
            phase: .bare,
            lasts: [],
            matchMarks: [],
            mileMarks: [],
            skidMarks: [],
            jamMarks: [],
            peelMarks: [],
            verdictChips: [],
            onboardingComplete: false,
            distanceUnit: .miles
        )
    }

    init(
        schemaVersion: Int,
        phase: CompareBenchPhase,
        lasts: [LastRecord],
        matchMarks: [MatchMark],
        mileMarks: [MileMark],
        skidMarks: [SkidMark],
        jamMarks: [JamMark],
        peelMarks: [PeelMark],
        verdictChips: [VerdictChip],
        onboardingComplete: Bool,
        distanceUnit: DistanceUnit
    ) {
        self.schemaVersion = schemaVersion
        self.phase = phase
        self.lasts = lasts
        self.matchMarks = matchMarks
        self.mileMarks = mileMarks
        self.skidMarks = skidMarks
        self.jamMarks = jamMarks
        self.peelMarks = peelMarks
        self.verdictChips = verdictChips
        self.onboardingComplete = onboardingComplete
        self.distanceUnit = distanceUnit
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let version = try container.decode(Int.self, forKey: .schemaVersion)
        switch version {
        case 1:
            schemaVersion = version
            phase = try container.decode(CompareBenchPhase.self, forKey: .phase)
            lasts = try container.decode([LastRecord].self, forKey: .lasts)
            matchMarks = try container.decode([MatchMark].self, forKey: .matchMarks)
            mileMarks = try container.decode([MileMark].self, forKey: .mileMarks)
            skidMarks = try container.decode([SkidMark].self, forKey: .skidMarks)
            jamMarks = try container.decode([JamMark].self, forKey: .jamMarks)
            peelMarks = try container.decode([PeelMark].self, forKey: .peelMarks)
            verdictChips = try container.decode([VerdictChip].self, forKey: .verdictChips)
            onboardingComplete = try container.decode(Bool.self, forKey: .onboardingComplete)
            distanceUnit = try container.decode(DistanceUnit.self, forKey: .distanceUnit)
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .schemaVersion,
                in: container,
                debugDescription: "Unknown compare schema \(version)."
            )
        }
    }
}

/// Miles or kilometres for the distance field. Stored amounts stay in the unit
/// the runner entered. The fold does not convert them.
enum DistanceUnit: String, Codable, Equatable, Sendable {
    case miles
    case kilometres
}

/// Aggregate phases. Bare is the empty library. Open has lasts and no pair.
/// Matched holds an active MatchMark. Divided has filed a VerdictChip.
enum CompareBenchPhase: String, Codable, Equatable, Sendable {
    case bare
    case open
    case matched
    case divided
}
