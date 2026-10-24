import SwiftUI
import UIKit

/// Distance unit, introduction, archive, reset, and support.
struct SettingsView: View {
    @ObservedObject var session: CompareBenchSession
    @Environment(\.dismiss) private var dismiss
    @State private var confirmReset = false
    @State private var reloading = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.s16) {
                    if let note = session.presentation.loadNote {
                        failure(note)
                    }
                    if session.presentation.shelf.isEmpty {
                        Text("No shoes on the bench.")
                            .font(TypeScale.font(.title))
                            .foregroundStyle(DesignTokens.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    units
                    archive
                    actions
                }
                .padding(Spacing.s16)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(DesignTokens.bg)
            .navigationTitle("Preferences")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    CloseControl()
                }
            }
        }
        .tint(DesignTokens.ink)
        .confirmationDialog(
            "Delete every shoe and outing?",
            isPresented: $confirmReset,
            titleVisibility: .visible
        ) {
            Button("Delete rotation", role: .destructive) {
                Task { @MainActor in
                    await session.resetAllData()
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The closet, distances, and split call are removed from this device.")
        }
    }

    private var units: some View {
        VStack(alignment: .leading, spacing: Spacing.s8) {
            Text("Distance unit")
                .font(TypeScale.font(.meta))
                .tracking(TypeScale.tracking(.meta))
                .textCase(.uppercase)
                .foregroundStyle(DesignTokens.muted)
            Button {
                session.chooseUnit(.miles)
            } label: {
                HStack {
                    Text("Miles")
                    Spacer(minLength: Spacing.s8)
                    if session.presentation.distanceUnit == .miles {
                        Text("Selected")
                            .font(TypeScale.font(.meta))
                    }
                }
            }
            .buttonStyle(BenchPressStyle(kind: session.presentation.distanceUnit == .miles ? .primary : .secondary))
            Button {
                session.chooseUnit(.kilometres)
            } label: {
                HStack {
                    Text("Kilometres")
                    Spacer(minLength: Spacing.s8)
                    if session.presentation.distanceUnit == .kilometres {
                        Text("Selected")
                            .font(TypeScale.font(.meta))
                    }
                }
            }
            .buttonStyle(BenchPressStyle(kind: session.presentation.distanceUnit == .kilometres ? .primary : .secondary))
            Text("Logged numbers stay as entered.")
                .font(TypeScale.font(.body))
                .foregroundStyle(DesignTokens.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Spacing.s16)
        .surfacePlate()
    }

    private var archive: some View {
        let retired = session.presentation.shelf.filter(\.retired)
        return VStack(alignment: .leading, spacing: Spacing.s8) {
            Text("Archived shoes")
                .font(TypeScale.font(.meta))
                .tracking(TypeScale.tracking(.meta))
                .textCase(.uppercase)
                .foregroundStyle(DesignTokens.muted)
            if retired.isEmpty {
                Text("No archived shoes.")
                    .font(TypeScale.font(.body))
                    .foregroundStyle(DesignTokens.ink)
            } else {
                ForEach(retired) { row in
                    Text(row.nickname)
                        .font(TypeScale.font(.call))
                        .foregroundStyle(DesignTokens.ink)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(maxWidth: .infinity, minHeight: Hit.min, alignment: .leading)
                }
            }
        }
        .padding(Spacing.s16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .surfacePlate()
    }

    private var actions: some View {
        VStack(spacing: Spacing.s8) {
            Button {
                session.reopenOnboarding()
                dismiss()
            } label: {
                Text("Show introduction")
            }
            .buttonStyle(BenchPressStyle(kind: .secondary))
            if let url = URL(string: "https://lastbench-compare.pro/contact-us") {
                Button {
                    UIApplication.shared.open(url)
                } label: {
                    HStack(spacing: Spacing.s8) {
                        Text("Contact support")
                        Spacer(minLength: Spacing.s8)
                        Image(systemName: "arrow.up.right")
                            .accessibilityHidden(true)
                    }
                }
                .buttonStyle(BenchPressStyle(kind: .secondary))
                .accessibilityHint("Opens the support page.")
            }
            Button {
                confirmReset = true
            } label: {
                Label("Delete rotation", systemImage: "trash")
            }
            .buttonStyle(BenchPressStyle(kind: .destructive))
        }
    }

    private func failure(_ note: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s8) {
            Text("Preferences failed. Try again.")
                .font(TypeScale.font(.call))
                .foregroundStyle(DesignTokens.ink)
            Text(note)
                .font(TypeScale.font(.body))
                .foregroundStyle(DesignTokens.ink)
                .fixedSize(horizontal: false, vertical: true)
            Button {
                reload()
            } label: {
                Text("Retry")
            }
            .buttonStyle(BenchPressStyle(kind: .primary))
            .disabled(reloading)
        }
        .padding(Spacing.s16)
        .surfacePlate()
    }

    private func reload() {
        guard !reloading else { return }
        reloading = true
        Task { @MainActor in
            await session.reload()
            reloading = false
        }
    }
}
