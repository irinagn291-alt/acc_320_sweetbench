import SwiftUI
import UIKit

/// Root. Reads `-ReviewScreen` once after the introduction is done.
struct ContentView: View {
    @StateObject private var session: CompareBenchSession
    @Environment(\.scenePhase) private var scenePhase
    @State private var cover: BenchCover?
    @State private var didReadHook = false
    @State private var wantSpinner = false
    @State private var dayStamp = Calendar.current.startOfDay(for: Date())

    init() {
        let directory = (try? CompareLedgerStore.applicationSupportDirectory())
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        _session = StateObject(wrappedValue: CompareBenchSession(store: CompareLedgerStore(directory: directory)))
    }

    var body: some View {
        Group {
            if !session.isReady {
                CompareView(session: session, open: { _ in })
                    .redacted(reason: .placeholder)
                    .allowsHitTesting(false)
            } else if !session.presentation.onboardingComplete {
                OnboardingView(session: session)
            } else {
                CompareView(session: session) { next in
                    cover = next
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignTokens.bg.ignoresSafeArea())
        .overlay {
            if wantSpinner && !session.isReady {
                ProgressView()
                    .tint(DesignTokens.accent)
                    .frame(minWidth: Hit.min, minHeight: Hit.min)
                    .padding(Spacing.s16)
                    .surfacePlate()
            }
        }
        .sheet(item: $cover) { destination in
            CoverHost(destination: destination, session: session) { next in
                cover = next
            }
                .modifier(SheetEntrance(plays: ReviewLaunch.screen == nil))
                .presentationBackground(DesignTokens.bg)
                .presentationCornerRadius(Radius.surface)
        }
        .task(id: session.isReady) {
            guard session.isReady else {
                try? await Task.sleep(nanoseconds: 150_000_000)
                if !session.isReady {
                    wantSpinner = true
                }
                return
            }
            wantSpinner = false
            applyHook()
        }
        .onChange(of: session.presentation.onboardingComplete) { _, _ in
            applyHook()
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            let start = Calendar.current.startOfDay(for: Date())
            if start != dayStamp {
                dayStamp = start
                session.refresh()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
            dayStamp = Calendar.current.startOfDay(for: Date())
            session.refresh()
        }
    }

    private func applyHook() {
        guard session.isReady, session.presentation.onboardingComplete, !didReadHook else { return }
        didReadHook = true
        let key = ReviewLaunch.screen
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            cover = Self.cover(for: key)
        }
    }

    private static func cover(for key: String?) -> BenchCover? {
        switch key {
        case "log", "ledger":
            .ledger
        case "goals", "insights":
            .insights
        case "library":
            .library
        case "settings":
            .settings
        case "compare":
            .pair
        case "twist":
            .twist
        default:
            nil
        }
    }
}

struct CoverHost: View {
    var destination: BenchCover
    @ObservedObject var session: CompareBenchSession
    var open: (BenchCover) -> Void

    var body: some View {
        switch destination {
        case .library:
            LibraryView(session: session)
        case .ledger:
            LedgerView(session: session)
        case .insights:
            InsightsView(session: session)
        case .settings:
            SettingsView(session: session)
        case .pair:
            PairSheetView(session: session)
        case .twist:
            TwistScreen(session: session) {
                open(.pair)
            }
        }
    }
}

#Preview {
    ContentView()
}
