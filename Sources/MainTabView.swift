import SwiftUI

public struct MainTabView: View {
    @StateObject private var settingsVM = SettingsViewModel()

    public init() {}

    public var body: some View {
        TabView {
            SearchView()
                .environmentObject(settingsVM)
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }

            StorefrontPickerView()
                .environmentObject(settingsVM)
                .tabItem {
                    Label("Countries", systemImage: "globe")
                }

            SettingsView()
                .environmentObject(settingsVM)
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .accentColor(.orange)
    }
}
