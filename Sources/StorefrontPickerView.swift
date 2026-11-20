import SwiftUI

// MARK: - Storefront Picker (Tab)

public struct StorefrontPickerView: View {
    @EnvironmentObject private var settingsVM: SettingsViewModel
    @State private var searchText = ""

    private var filteredStorefronts: [Storefront] {
        if searchText.isEmpty { return StorefrontCatalog.all }
        let query = searchText.lowercased()
        return StorefrontCatalog.all.filter {
            $0.name.lowercased().contains(query) ||
            $0.code.lowercased().contains(query) ||
            $0.currencyCode.lowercased().contains(query)
        }
    }

    public init() {}

    public var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach(filteredStorefronts) { sf in
                        Button {
                            settingsVM.toggleStorefront(sf)
                        } label: {
                            HStack {
                                Text(sf.flag)
                                    .font(.title2)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(sf.name)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    Text("\(sf.code) · \(sf.currencyCode)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                if settingsVM.isFavorite(sf) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.orange)
                                        .font(.title3)
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundColor(.secondary)
                                        .font(.title3)
                                }
                            }
                        }
                    }
                } header: {
                    Text("\(settingsVM.favoriteStorefronts.count) selected")
                } footer: {
                    Text("Selected countries will be used for price comparison. Tap to toggle.")
                }
            }
            .listStyle(.insetGrouped)
            .searchable(text: $searchText, prompt: "Search countries...")
            .navigationTitle("Countries")
        }
        .navigationViewStyle(.stack)
    }
}

// MARK: - Storefront Selection Sheet (for Compare screen)

public struct StorefrontSelectionSheet: View {
    @Binding public var selectedStorefronts: [Storefront]
    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss

    private var filteredStorefronts: [Storefront] {
        if searchText.isEmpty { return StorefrontCatalog.all }
        let query = searchText.lowercased()
        return StorefrontCatalog.all.filter {
            $0.name.lowercased().contains(query) ||
            $0.code.lowercased().contains(query)
        }
    }

    public var body: some View {
        NavigationView {
            List {
                Section {
                    Button {
                        selectedStorefronts = StorefrontCatalog.all
                    } label: {
                        Label("Select All (\(StorefrontCatalog.all.count))", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.orange)
                    }

                    Button {
                        selectedStorefronts = StorefrontCatalog.popularDefaults
                    } label: {
                        Label("Popular Only", systemImage: "star.fill")
                            .foregroundColor(.yellow)
                    }

                    Button {
                        selectedStorefronts = []
                    } label: {
                        Label("Deselect All", systemImage: "xmark.circle")
                            .foregroundColor(.red)
                    }
                }

                Section("Storefronts") {
                    ForEach(filteredStorefronts) { sf in
                        Button {
                            toggleSelection(sf)
                        } label: {
                            HStack {
                                Text(sf.flag)
                                    .font(.title3)
                                Text(sf.name)
                                    .foregroundColor(.primary)
                                Text("(\(sf.currencyCode))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                Spacer()

                                if selectedStorefronts.contains(sf) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.orange)
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .searchable(text: $searchText, prompt: "Search countries...")
            .navigationTitle("Select Countries")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .bold()
                }
            }
        }
    }

    private func toggleSelection(_ sf: Storefront) {
        if let idx = selectedStorefronts.firstIndex(of: sf) {
            selectedStorefronts.remove(at: idx)
        } else {
            selectedStorefronts.append(sf)
        }
    }
}
