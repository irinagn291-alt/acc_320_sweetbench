import SwiftUI

/// Closet sheet. Owned shoes, prices, and relative grades.
struct LibraryView: View {
    @ObservedObject var session: CompareBenchSession
    @FocusState private var focus: AddFocus?
    @State private var nickname = ""
    @State private var priceText = ""
    @State private var disposalText = ""
    @State private var formNote: String?
    @State private var adding = false
    @State private var reloading = false
    @State private var confirmArchive = false
    @State private var pendingArchive: UUID?

    private enum AddFocus: Hashable {
        case nickname
        case price
        case disposal
    }

    var body: some View {
        NavigationStack {
            Group {
                if session.presentation.shelf.isEmpty && !adding {
                    VStack(alignment: .leading, spacing: Spacing.s16) {
                        if let note = session.presentation.loadNote {
                            failure(note)
                        }
                        FullEmpty(
                            image: "lsb_EmptyRotationCutout",
                            title: "The closet is empty.",
                            line: "Add a shoe you own.",
                            actionTitle: "Add shoe"
                        ) {
                            adding = true
                        }
                    }
                    .padding(Spacing.s16)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: Spacing.s16) {
                            if let note = session.presentation.loadNote {
                                failure(note)
                            }
                            editor
                            populated
                        }
                        .padding(Spacing.s16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .scrollDismissesKeyboard(.immediately)
                }
            }
            .background(DesignTokens.bg)
            .navigationTitle("Closet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    CloseControl()
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Button(focus == .disposal ? "Done" : "Next") {
                        advance()
                    }
                    .frame(minHeight: Hit.min)
                }
            }
        }
        .tint(DesignTokens.ink)
        .confirmationDialog(
            "Archive this shoe?",
            isPresented: $confirmArchive,
            titleVisibility: .visible
        ) {
            Button("Archive shoe", role: .destructive) {
                if let pendingArchive {
                    session.retire(id: pendingArchive)
                }
                pendingArchive = nil
            }
            Button("Cancel", role: .cancel) {
                pendingArchive = nil
            }
        } message: {
            Text("The shoe stays on this device and leaves the active closet.")
        }
    }

    private var editor: some View {
        VStack(alignment: .leading, spacing: Spacing.s12) {
            Text("Add shoe")
                .font(TypeScale.font(.title))
                .foregroundStyle(DesignTokens.ink)
                .fixedSize(horizontal: false, vertical: true)
            TextField("Nickname", text: $nickname)
                .focused($focus, equals: .nickname)
                .textInputAutocapitalization(.words)
                .font(TypeScale.font(.body))
                .foregroundStyle(DesignTokens.ink)
                .padding(Spacing.s12)
                .frame(minHeight: Hit.min)
                .surfacePlate()
            TextField("Purchase price", text: $priceText)
                .focused($focus, equals: .price)
                .keyboardType(.decimalPad)
                .font(TypeScale.font(.body))
                .foregroundStyle(DesignTokens.ink)
                .padding(Spacing.s12)
                .frame(minHeight: Hit.min)
                .surfacePlate()
            TextField("Disposal value", text: $disposalText)
                .focused($focus, equals: .disposal)
                .keyboardType(.decimalPad)
                .font(TypeScale.font(.body))
                .foregroundStyle(DesignTokens.ink)
                .padding(Spacing.s12)
                .frame(minHeight: Hit.min)
                .surfacePlate()
            if let formNote {
                Text(formNote)
                    .font(TypeScale.font(.body))
                    .foregroundStyle(DesignTokens.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Button {
                save()
            } label: {
                Text("Save shoe")
            }
            .buttonStyle(BenchPressStyle(kind: .primary))
            .disabled(reloading)
        }
        .padding(Spacing.s16)
        .surfacePlate()
    }

    private var populated: some View {
        let rows = session.presentation.shelf.sorted { lhs, rhs in
            if lhs.retired != rhs.retired { return !lhs.retired }
            return lhs.nickname < rhs.nickname
        }
        return VStack(alignment: .leading, spacing: Spacing.s12) {
            if let hero = rows.first {
                heroRow(hero)
                ForEach(Array(rows.dropFirst())) { row in
                    compactRow(row)
                }
            }
        }
    }

    private func heroRow(_ row: ComparePresentation.ShelfReading) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s8) {
            HStack(spacing: Spacing.s8) {
                Text(row.nickname)
                    .font(TypeScale.font(.title))
                    .foregroundStyle(DesignTokens.ink)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer(minLength: Spacing.s8)
                cost(row)
            }
            meta(row)
            archiveButton(row)
        }
        .padding(Spacing.s16)
        .surfacePlate()
    }

    private func compactRow(_ row: ComparePresentation.ShelfReading) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s8) {
            HStack(spacing: Spacing.s8) {
                Text(row.nickname)
                    .font(TypeScale.font(.call))
                    .foregroundStyle(DesignTokens.ink)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer(minLength: Spacing.s8)
                cost(row)
            }
            meta(row)
            archiveButton(row)
        }
        .padding(Spacing.s12)
        .surfacePlate()
    }

    private func cost(_ row: ComparePresentation.ShelfReading) -> some View {
        Group {
            if let value = row.costPerMile {
                Text(value, format: .currency(code: "USD").precision(.fractionLength(0...1)))
                    .contentTransition(.numericText(value: value))
                    .animation(Motion.press, value: value)
            } else {
                Text("unknown")
            }
        }
        .font(TypeScale.font(.call))
        .foregroundStyle(DesignTokens.accent)
        .monospacedDigit()
        .fixedSize(horizontal: true, vertical: true)
        .layoutPriority(1)
    }

    private func meta(_ row: ComparePresentation.ShelfReading) -> some View {
        HStack(spacing: Spacing.s8) {
            GradeChip(band: row.band)
            Text(row.ageDays, format: .number.precision(.fractionLength(0)))
            Text("days")
            Text(row.purchasePrice, format: .currency(code: "USD").precision(.fractionLength(0...1)))
            if row.retired {
                Text("Archived")
            }
        }
        .font(TypeScale.font(.meta))
        .foregroundStyle(DesignTokens.muted)
    }

    private func archiveButton(_ row: ComparePresentation.ShelfReading) -> some View {
        Button {
            pendingArchive = row.id
            confirmArchive = true
        } label: {
            Label("Archive", systemImage: "archivebox")
        }
        .buttonStyle(BenchPressStyle(kind: .destructive))
        .disabled(row.retired)
        .accessibilityLabel("Archive \(row.nickname)")
    }

    private func failure(_ note: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s8) {
            Text("Closet failed. Try again.")
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

    private func advance() {
        switch focus {
        case .nickname:
            focus = .price
        case .price:
            focus = .disposal
        default:
            focus = nil
        }
    }

    private func save() {
        let name = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            formNote = "Name refused. Enter a nickname."
            return
        }
        guard let price = DecimalInput.amount(from: priceText) else {
            formNote = "Price refused. Enter zero or more."
            return
        }
        let disposal: Double
        if disposalText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            disposal = 0
        } else if let parsed = DecimalInput.amount(from: disposalText) {
            disposal = parsed
        } else {
            formNote = "Disposal refused. Enter zero or more."
            return
        }
        formNote = nil
        session.adopt(
            last: LastRecord(
                nickname: name,
                purchasePrice: price,
                disposalValue: disposal,
                acquiredAt: Date()
            )
        )
        nickname = ""
        priceText = ""
        disposalText = ""
        focus = nil
        adding = false
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

struct FullEmpty: View {
    var image: String
    var title: String
    var line: String
    var actionTitle: String
    var action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s16) {
            Image(image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .frame(maxHeight: Spacing.s48 * 5)
                .clipped()
                .accessibilityHidden(true)
            Text(title)
                .font(TypeScale.font(.title))
                .foregroundStyle(DesignTokens.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(line)
                .font(TypeScale.font(.body))
                .foregroundStyle(DesignTokens.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: Spacing.s24)
            Button(actionTitle, action: action)
                .buttonStyle(BenchPressStyle(kind: .primary))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}
