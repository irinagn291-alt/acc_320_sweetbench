import Combine
import Foundation

/// Main-actor seam the compare chrome will bind. It owns the load task,
/// applies the fold, and asks the ledger to project the record to disk.
@MainActor
final class CompareBenchSession: ObservableObject {
    @Published private(set) var presentation: ComparePresentation
    @Published private(set) var isReady = false
    private let store: CompareLedgerStore
    private var record: CompareRootRecord
    private var loadTask: Task<Void, Never>?
    private var chain: Task<Void, Never>?

    init(store: CompareLedgerStore, now: Date = Date()) {
        self.store = store
        self.record = .empty
        self.presentation = ComparePresentation.make(record: .empty, now: now)
        loadTask = Task { [weak self] in
            await self?.reload(now: now)
        }
    }

    func reload(now: Date = Date()) async {
        await store.load()
        await store.seedDemoIfNeeded(now: now)
        record = await store.current()
        let note = await store.loadNote
        presentation = ComparePresentation.make(record: record, loadNote: note, now: now)
        isReady = true
    }

    func mile(lastID: UUID, distance: Double, now: Date = Date()) {
        apply(CompareBenchFold.mile(record, lastID: lastID, distance: distance, now: now), now: now)
    }

    func match(leftLastID: UUID, rightLastID: UUID, now: Date = Date()) {
        apply(
            CompareBenchFold.match(record, leftLastID: leftLastID, rightLastID: rightLastID, now: now),
            now: now
        )
    }

    func peel(now: Date = Date()) {
        apply(CompareBenchFold.peel(record, now: now), now: now)
    }

    func adopt(last: LastRecord, now: Date = Date()) {
        record = CompareBenchFold.adoptLast(record, last: last, now: now)
        publish(refusal: nil, now: now)
    }

    func resetAllData(now: Date = Date()) async {
        await chain?.value
        chain = nil
        await store.resetAllData()
        record = await store.current()
        presentation = ComparePresentation.make(record: record, now: now)
    }

    func flush() async {
        await chain?.value
        await store.flush()
    }

    /// Marks the introduction done without touching the rotation.
    func finishOnboarding(now: Date = Date()) {
        record.onboardingComplete = true
        publish(refusal: nil, now: now)
    }

    /// Settings can show the introduction again. The rotation stays.
    func reopenOnboarding(now: Date = Date()) {
        record.onboardingComplete = false
        publish(refusal: nil, now: now)
    }

    func chooseUnit(_ unit: DistanceUnit, now: Date = Date()) {
        record.distanceUnit = unit
        publish(refusal: nil, now: now)
    }

    func retire(id: UUID, now: Date = Date()) {
        guard let index = record.lasts.firstIndex(where: { $0.id == id }) else { return }
        record.lasts[index].retiredAt = now
        publish(refusal: nil, now: now)
    }

    /// Recomputes ages when the calendar day changes. Does not write disk.
    func refresh(now: Date = Date()) {
        let note = presentation.loadNote
        presentation = ComparePresentation.make(
            record: record,
            refusal: presentation.refusal,
            loadNote: note,
            now: now
        )
    }

    private func apply(_ outcome: FoldOutcome, now: Date) {
        record = outcome.record
        publish(refusal: outcome.refusal, now: now)
    }

    private func publish(refusal: BenchRefusal?, now: Date) {
        let snapshot = record
        presentation = ComparePresentation.make(record: snapshot, refusal: refusal, now: now)
        let previous = chain
        chain = Task {
            await previous?.value
            await store.replace(snapshot)
        }
    }
}
