import SwiftUI

public struct SettingsView: View {
    @EnvironmentObject private var settingsVM: SettingsViewModel

    public init() {}

    public var body: some View {
        NavigationView {
            List {
                // About
                Section {
                    HStack(spacing: 16) {
                        Image(systemName: "tag.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.orange)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("PriceTag")
                                .font(.title2.bold())
                            Text("v1.0.0")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("Compare App Store IAP prices across countries")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }

                // Selected countries summary
                Section("Default Countries") {
                    if settingsVM.favoriteStorefronts.isEmpty {
                        Text("No countries selected")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(settingsVM.favoriteStorefronts) { sf in
                            HStack {
                                Text(sf.flag)
                                Text(sf.name)
                                    .font(.subheadline)
                                Spacer()
                                Text(sf.currencyCode)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .onDelete { indices in
                            settingsVM.favoriteStorefronts.remove(atOffsets: indices)
                        }
                        .onMove { from, to in
                            settingsVM.favoriteStorefronts.move(fromOffsets: from, toOffset: to)
                        }
                    }
                }

                // How it works
                Section("How It Works") {
                    VStack(alignment: .leading, spacing: 8) {
                        infoRow(icon: "1.circle.fill", color: .orange,
                                text: "Search for any app on the App Store")
                        infoRow(icon: "2.circle.fill", color: .orange,
                                text: "Tap the app to see its detail page")
                        infoRow(icon: "3.circle.fill", color: .orange,
                                text: "Hit 'Compare Prices' to query all selected storefronts")
                        infoRow(icon: "4.circle.fill", color: .orange,
                                text: "See app price & every IAP side-by-side across countries")
                    }
                    .padding(.vertical, 4)
                }

                Section("Data Source") {
                    Label("iTunes Search API", systemImage: "server.rack")
                    Label("Prices in local currency", systemImage: "dollarsign.circle")
                    Label("No account required", systemImage: "person.slash")
                }

                Section {
                    Label("Made with ❤️ by Moe", systemImage: "hammer.fill")
                        .foregroundColor(.secondary)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .toolbar {
                EditButton()
            }
        }
        .navigationViewStyle(.stack)
    }

    private func infoRow(icon: String, color: Color, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.body)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}
