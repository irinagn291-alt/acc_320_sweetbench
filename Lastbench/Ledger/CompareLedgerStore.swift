import Foundation

/// Persistence seam. The in-memory compare root is the source of truth.
/// UserDefaults holds one encoded blob under a versioned key. The same blob
/// is written atomically to Application Support. The UI never calls this type.
actor CompareLedgerStore {
    static let storageKey = "lsb.compare.root.v1"
    static let demoKey = "lsb.demo.v1"
    private static let fileName = "compare-root.json"

    private let directory: URL
    private let defaults: UserDefaults
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private var record: CompareRootRecord
    private var generation = 0
    private var pending: Task<Void, Never>?
    private(set) var loadNote: String?

    init(directory: URL, suiteName: String? = nil, record: CompareRootRecord = .empty) {
        self.directory = directory
        if let suiteName, let suite = UserDefaults(suiteName: suiteName) {
            self.defaults = suite
        } else {
            self.defaults = .standard
        }
        self.record = record
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        encoder.dateEncodingStrategy = .millisecondsSince1970
        self.encoder = encoder
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        self.decoder = decoder
    }

    static func applicationSupportDirectory() throws -> URL {
        guard let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            throw CocoaError(.fileNoSuchFile)
        }
        return base.appendingPathComponent("Sweetbench", isDirectory: true)
    }

    func current() -> CompareRootRecord {
        record
    }

    func replace(_ next: CompareRootRecord) {
        record = next
        scheduleSave()
    }

    func flush() async {
        pending?.cancel()
        pending = nil
        generation += 1
        await writeNow()
    }

    func load() async {
        let url = fileURL()
        if let data = try? Data(contentsOf: url) {
            if let decoded = decode(data) {
                record = decoded
                loadNote = nil
                return
            }
            archiveCorrupt(url)
        }
        let backup = backupURL()
        if let data = try? Data(contentsOf: backup), let decoded = decode(data) {
            record = decoded
            loadNote = "Recovered the last good rotation."
            return
        }
        if let data = defaults.data(forKey: Self.storageKey), let decoded = decode(data) {
            record = decoded
            loadNote = nil
            return
        }
        record = .empty
        loadNote = "The rotation file could not be read. Starting empty."
    }

    func resetAllData() async {
        pending?.cancel()
        pending = nil
        generation += 1
        record = .empty
        loadNote = nil
        defaults.removeObject(forKey: Self.storageKey)
        defaults.removeObject(forKey: Self.demoKey)
        let urls = [fileURL(), backupURL(), fileURL().appendingPathExtension("corrupt")]
        for url in urls where FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.removeItem(at: url)
            } catch {
                loadNote = "Reset could not remove a leftover rotation file."
            }
        }
    }

    func seedDemoIfNeeded(now: Date = Date()) async {
        #if targetEnvironment(simulator)
        if defaults.bool(forKey: Self.demoKey) { return }
        if !record.lasts.isEmpty {
            defaults.set(true, forKey: Self.demoKey)
            return
        }
        record = CompareBenchFold.demoRotation(now: now)
        defaults.set(true, forKey: Self.demoKey)
        await writeNow()
        #endif
    }

    private func scheduleSave() {
        generation += 1
        let token = generation
        pending?.cancel()
        pending = Task {
            do {
                try await Task.sleep(nanoseconds: 300_000_000)
            } catch is CancellationError {
                return
            } catch {
                loadNote = "Save wait ended early."
                return
            }
            guard token == generation else { return }
            await writeNow()
        }
    }

    private func writeNow() async {
        do {
            try persist(record)
            loadNote = nil
        } catch {
            loadNote = "The rotation could not be saved. It stays on screen."
        }
    }

    private func persist(_ snapshot: CompareRootRecord) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = fileURL()
        let data = try encoder.encode(snapshot)
        if FileManager.default.fileExists(atPath: url.path) {
            let backup = backupURL()
            if FileManager.default.fileExists(atPath: backup.path) {
                try FileManager.default.removeItem(at: backup)
            }
            try FileManager.default.copyItem(at: url, to: backup)
        }
        try data.write(to: url, options: .atomic)
        var values = URLResourceValues()
        values.isExcludedFromBackup = false
        var writable = url
        try writable.setResourceValues(values)
        defaults.set(data, forKey: Self.storageKey)
    }

    private func decode(_ data: Data) -> CompareRootRecord? {
        try? decoder.decode(CompareRootRecord.self, from: data)
    }

    private func archiveCorrupt(_ url: URL) {
        let corrupt = url.appendingPathExtension("corrupt")
        if FileManager.default.fileExists(atPath: corrupt.path) {
            try? FileManager.default.removeItem(at: corrupt)
        }
        try? FileManager.default.copyItem(at: url, to: corrupt)
    }

    private func fileURL() -> URL {
        directory.appendingPathComponent(Self.fileName)
    }

    private func backupURL() -> URL {
        directory.appendingPathComponent(Self.fileName + ".backup")
    }
}
