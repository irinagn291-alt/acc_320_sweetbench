import XCTest
@testable import Lastbench

final class LastbenchTests: XCTestCase {
    private let calendar = Calendar(identifier: .gregorian)

    func testCostPerMileUsesPriceMinusDisposalOverDistance() {
        let cost = RotationEfficiency.costPerMile(price: 160, disposal: 20, miles: 14)
        XCTAssertEqual(cost, 140 / 14, accuracy: 0.0001)
        let untouched = RotationEfficiency.costPerMile(price: 90, disposal: 0, miles: 0)
        XCTAssertEqual(untouched, 90, accuracy: 0.0001)
    }

    func testGradeNeedsFivePeersAndSevenDays() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let young = LastRecord(nickname: "New", purchasePrice: 10, acquiredAt: now)
        let peers = (0..<5).map { index in
            LastRecord(
                nickname: "P\(index)",
                purchasePrice: Double(100 + index * 40),
                acquiredAt: daysAgo(21, from: now)
            )
        }
        XCTAssertEqual(
            RotationEfficiency.band(for: young, among: peers + [young], mileMarks: [], now: now),
            .insufficientData
        )
        XCTAssertEqual(
            RotationEfficiency.band(for: peers[0], among: Array(peers.prefix(4)), mileMarks: [], now: now),
            .insufficientData
        )
        let best = peers[0]
        let band = RotationEfficiency.band(for: best, among: peers, mileMarks: [], now: now)
        XCTAssertEqual(band, .aPlus)
        let worst = peers[4]
        XCTAssertEqual(
            RotationEfficiency.band(for: worst, among: peers, mileMarks: [], now: now),
            .f
        )
    }

    func testMileOnOpenWritesSkidAndKeepsPhase() {
        var record = CompareRootRecord.empty
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let last = LastRecord(nickname: "Track", purchasePrice: 120, acquiredAt: daysAgo(3, from: now))
        record = CompareBenchFold.adoptLast(record, last: last, now: now)
        XCTAssertEqual(record.phase, .open)
        let refused = CompareBenchFold.mile(record, lastID: last.id, distance: 5, now: now)
        XCTAssertEqual(refused.refusal, .mileOnOpen)
        XCTAssertEqual(refused.record.phase, .open)
        XCTAssertTrue(refused.record.mileMarks.isEmpty)
        XCTAssertEqual(refused.record.skidMarks.count, 1)

        let bare = CompareBenchFold.mile(.empty, lastID: UUID(), distance: 5, now: now)
        XCTAssertEqual(bare.refusal, .mileOnOpen)
        XCTAssertEqual(bare.record.phase, .bare)
        XCTAssertEqual(bare.record.skidMarks.count, 1)
    }

    func testMileRejectsEmptyAndInvalidDistanceAfterMatch() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let matched = matchedPair(now: now)
        let left = matched.lasts[0].id
        let zero = CompareBenchFold.mile(matched, lastID: left, distance: 0, now: now)
        XCTAssertEqual(zero.refusal, .invalidDistance)
        XCTAssertTrue(zero.record.mileMarks.isEmpty)
        let negative = CompareBenchFold.mile(matched, lastID: left, distance: -2, now: now)
        XCTAssertEqual(negative.refusal, .invalidDistance)
        let logged = CompareBenchFold.mile(matched, lastID: left, distance: 8, now: now)
        XCTAssertNil(logged.refusal)
        XCTAssertEqual(logged.record.phase, .matched)
        XCTAssertEqual(logged.record.mileMarks.count, 1)
        let cost = CompareBenchFold.costPerMile(in: logged.record, lastID: left)
        XCTAssertEqual(cost ?? -1, 150 / 8, accuracy: 0.0001)
    }

    func testSecondMatchWhileMatchedWritesJam() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let matched = matchedPair(now: now)
        let again = CompareBenchFold.match(
            matched,
            leftLastID: matched.lasts[0].id,
            rightLastID: matched.lasts[1].id,
            now: now
        )
        XCTAssertEqual(again.refusal, .matchWhileMatched)
        XCTAssertEqual(again.record.phase, .matched)
        XCTAssertEqual(again.record.matchMarks.count, 1)
        XCTAssertEqual(again.record.jamMarks.count, 1)
    }

    func testVerdictChipAfterFourMilesAndFourteenDays() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        var record = matchedPair(now: now, age: 20, leftPrice: 80, rightPrice: 160)
        let left = record.lasts[0].id
        let right = record.lasts[1].id
        for index in 0..<3 {
            let leftStep = CompareBenchFold.mile(record, lastID: left, distance: 5, now: now.addingTimeInterval(Double(index)))
            XCTAssertNil(leftStep.refusal)
            XCTAssertEqual(leftStep.record.phase, .matched)
            record = leftStep.record
            let rightStep = CompareBenchFold.mile(record, lastID: right, distance: 2, now: now.addingTimeInterval(Double(index) + 0.5))
            record = rightStep.record
        }
        XCTAssertTrue(record.verdictChips.isEmpty)
        XCTAssertEqual(record.phase, .matched)
        let fourthLeft = CompareBenchFold.mile(record, lastID: left, distance: 5, now: now.addingTimeInterval(10))
        record = fourthLeft.record
        XCTAssertEqual(record.phase, .matched)
        let fourthRight = CompareBenchFold.mile(record, lastID: right, distance: 2, now: now.addingTimeInterval(11))
        record = fourthRight.record
        XCTAssertEqual(record.phase, .divided)
        XCTAssertEqual(record.verdictChips.count, 1)
        XCTAssertEqual(record.verdictChips[0].lowerLastID, left)
        let peeled = CompareBenchFold.peel(record, now: now.addingTimeInterval(12))
        XCTAssertNil(peeled.refusal)
        XCTAssertEqual(peeled.record.mileMarks.count, 7)
        XCTAssertEqual(peeled.record.peelMarks.count, 1)
        XCTAssertEqual(peeled.record.phase, .matched)
        XCTAssertEqual(peeled.record.verdictChips.count, 1)
    }

    func testPresentationKeepsMileEnabledOnlyWhenMatched() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let open = ComparePresentation.make(record: .empty, now: now)
        XCTAssertEqual(open.phase, .bare)
        XCTAssertFalse(open.mileEnabled)
        let matched = matchedPair(now: now)
        let live = ComparePresentation.make(record: matched, now: now)
        XCTAssertEqual(live.phase, .matched)
        XCTAssertTrue(live.mileEnabled)
        XCTAssertEqual(live.left?.nickname, "Left")
        XCTAssertEqual(live.right?.nickname, "Right")
    }

    func testPersistenceRoundTrip() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("lastbench-tests-\(UUID().uuidString)", isDirectory: true)
        let suite = "lsb.tests.\(UUID().uuidString)"
        UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite)
        let store = CompareLedgerStore(directory: directory, suiteName: suite)
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        var record = matchedPair(now: now)
        let logged = CompareBenchFold.mile(record, lastID: record.lasts[0].id, distance: 3.5, now: now)
        record = logged.record
        await store.replace(record)
        await store.flush()
        let reloaded = CompareLedgerStore(directory: directory, suiteName: suite)
        await reloaded.load()
        let loaded = await reloaded.current()
        XCTAssertEqual(loaded, record)
        XCTAssertEqual(loaded.phase, .matched)
        XCTAssertEqual(loaded.mileMarks.count, 1)
        await reloaded.resetAllData()
        let cleared = await reloaded.current()
        XCTAssertEqual(cleared, .empty)
        let third = CompareLedgerStore(directory: directory, suiteName: suite)
        await third.load()
        let clearedOnDisk = await third.current()
        XCTAssertTrue(clearedOnDisk.lasts.isEmpty)
        UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite)
        try? FileManager.default.removeItem(at: directory)
    }

    func testReviewLaunchParsesScreenArgument() {
        XCTAssertNil(ReviewLaunch.screen(in: ["Lastbench"]))
        XCTAssertNil(ReviewLaunch.screen(in: ["Lastbench", "-ReviewScreen"]))
        XCTAssertEqual(
            ReviewLaunch.screen(in: ["Lastbench", "-ReviewScreen", "today"]),
            "today"
        )
        XCTAssertEqual(
            ReviewLaunch.screen(in: ["Lastbench", "-ReviewScreen", "ledger"]),
            "ledger"
        )
        XCTAssertEqual(ReviewLaunch.argument, "-ReviewScreen")
    }

    private func matchedPair(now: Date, age: Int = 10, leftPrice: Double = 150, rightPrice: Double = 130) -> CompareRootRecord {
        let left = LastRecord(nickname: "Left", purchasePrice: leftPrice, acquiredAt: daysAgo(age, from: now))
        let right = LastRecord(nickname: "Right", purchasePrice: rightPrice, acquiredAt: daysAgo(age, from: now))
        var record = CompareRootRecord.empty
        record = CompareBenchFold.adoptLast(record, last: left, now: now)
        record = CompareBenchFold.adoptLast(record, last: right, now: now)
        let paired = CompareBenchFold.match(record, leftLastID: left.id, rightLastID: right.id, now: now)
        return paired.record
    }

    private func daysAgo(_ days: Int, from now: Date) -> Date {
        calendar.date(byAdding: .day, value: -days, to: now) ?? now
    }
}
