import SwiftUI

public enum DisplayMode: String, CaseIterable, Identifiable {
    case byCountry = "By Country"
    case compare = "Compare"

    public var id: String { rawValue }
}

public struct AppDetailView: View {
    public let app: AppResult
    @StateObject private var compareVM: CompareViewModel
    @EnvironmentObject private var settingsVM: SettingsViewModel
    @State private var showStorefrontPicker = false
    @State private var displayMode: DisplayMode = .byCountry

    public init(app: AppResult) {
        self.app = app
        _compareVM = StateObject(wrappedValue: CompareViewModel(app: app))
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                appHeader
                actionButtons
                infoBanner
                viewModePicker
                comparisonSection
            }
            .padding()
        }
        .navigationTitle("Price Tag")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            compareVM.selectedStorefronts = settingsVM.favoriteStorefronts
            if compareVM.priceResults.isEmpty && !compareVM.isLoading {
                compareVM.startComparison()
            }
        }
        .sheet(isPresented: $showStorefrontPicker) {
            StorefrontSelectionSheet(
                selectedStorefronts: $compareVM.selectedStorefronts
            )
            .onDisappear {
                compareVM.startComparison()
            }
        }
    }

    // MARK: - App Header

    private var appHeader: some View {
        HStack(spacing: 16) {
            AsyncImage(url: app.artworkURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray5))
                        .overlay(
                            Image(systemName: "app.fill")
                                .font(.title)
                                .foregroundColor(.secondary)
                        )
                default:
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray5))
                        .overlay(ProgressView())
                }
            }
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            VStack(alignment: .leading, spacing: 4) {
                Text(app.trackName)
                    .font(.title3.bold())
                    .lineLimit(2)

                if let seller = app.sellerName {
                    Text(seller)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 8) {
                    if let price = app.formattedPrice {
                        Label(price, systemImage: "tag.fill")
                            .font(.caption.bold())
                            .foregroundColor(price == "Free" ? .green : .orange)
                    }

                    if let rating = app.averageUserRating {
                        Label(String(format: "%.1f", rating), systemImage: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }

                    Text(app.formattedFileSize)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                showStorefrontPicker = true
            } label: {
                Label("\(compareVM.selectedStorefronts.count) Countries", systemImage: "globe")
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.blue)

            Button {
                compareVM.startComparison()
            } label: {
                Label(compareVM.isLoading ? "Comparing..." : "Reload Prices", systemImage: "arrow.triangle.2.circlepath")
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            .disabled(compareVM.isLoading || compareVM.selectedStorefronts.isEmpty)
        }
    }

    // MARK: - Info Banner

    private var infoBanner: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle.fill")
                .foregroundColor(.blue)
                .font(.subheadline)
            Text("Apple publicly lists the top 7–10 in-app purchases per country storefront. Switch views below to see all packages by country or side-by-side.")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(10)
        .background(Color.blue.opacity(0.08))
        .cornerRadius(10)
    }

    // MARK: - View Mode Picker

    private var viewModePicker: some View {
        Picker("View Mode", selection: $displayMode) {
            ForEach(DisplayMode.allCases) { mode in
                Text(mode.rawValue).tag(mode)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Comparison Section

    private var comparisonSection: some View {
        VStack(spacing: 16) {
            if compareVM.isLoading {
                VStack(spacing: 8) {
                    ProgressView(value: Double(compareVM.progress), total: Double(max(1, compareVM.total)))
                        .tint(.orange)
                    Text("Checking \(compareVM.progress)/\(compareVM.total) storefronts...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }

            if !compareVM.priceResults.isEmpty {
                if displayMode == .byCountry {
                    byCountryView
                } else {
                    compareGridView
                }
            }
        }
    }

    // MARK: - By Country View

    private var byCountryView: some View {
        VStack(spacing: 12) {
            ForEach(compareVM.priceResults) { result in
                StorefrontDetailCard(result: result)
            }
        }
    }

    // MARK: - Compare Grid View

    private var compareGridView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // App Base Price Section
            appBasePriceSection

            // Grouped IAP Cards
            if !compareVM.comparisonGroups.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("In-App Purchases Comparison", systemImage: "creditcard.fill")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Spacer()
                        Text("\(compareVM.comparisonGroups.count) groups")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    ForEach(compareVM.comparisonGroups) { group in
                        GroupedIAPCard(group: group, compareVM: compareVM)
                    }
                }
            } else if !compareVM.isLoading {
                noIAPsCard
            }
        }
    }

    // MARK: - App Base Price Section

    private var appBasePriceSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("App Store Price", systemImage: "dollarsign.circle.fill")
                .font(.headline)
                .foregroundColor(.primary)

            VStack(spacing: 6) {
                ForEach(compareVM.priceResults) { result in
                    HStack {
                        Text(result.storefront.flag)
                            .font(.title3)
                        Text(result.storefront.name)
                            .font(.subheadline)
                        Text("(\(result.storefront.currencyCode))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        if let error = result.error {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text(result.appPrice ?? "Free")
                                .font(.subheadline.bold())
                                .foregroundColor(result.appPrice == "Free" ? .green : .primary)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
            }
        }
    }

    // MARK: - No IAPs Card

    private var noIAPsCard: some View {
        VStack(spacing: 8) {
            Image(systemName: "info.circle")
                .font(.title2)
                .foregroundColor(.secondary)
            Text("No In-App Purchases Listed")
                .font(.subheadline.bold())
            Text("This app either does not offer in-app purchases or they are not public on the App Store storefronts.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Storefront Detail Card (By Country View)

public struct StorefrontDetailCard: View {
    public let result: PriceResult

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack {
                Text(result.storefront.flag)
                    .font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text(result.storefront.name)
                        .font(.headline)
                    Text("Currency: \(result.storefront.currencyCode) · Base App: \(result.appPrice ?? "Free")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text("\(result.iapPrices.count) packages")
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.15))
                    .foregroundColor(.orange)
                    .cornerRadius(8)
            }

            Divider()

            if let error = result.error {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 4)
            } else if result.iapPrices.isEmpty {
                Text("No in-app purchases listed for this storefront.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 4)
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(result.iapPrices.enumerated()), id: \.offset) { index, iap in
                        HStack(alignment: .top) {
                            Text("\(index + 1).")
                                .font(.caption.bold())
                                .foregroundColor(.secondary)
                                .frame(width: 22, alignment: .leading)
                            Text(iap.name)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            Spacer()
                            Text(iap.formattedPrice)
                                .font(.subheadline.bold())
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(Color(.systemGray6))
        .cornerRadius(14)
    }
}

// MARK: - Grouped IAP Card (Compare View)

public struct GroupedIAPCard: View {
    public let group: IAPGroup
    public let compareVM: CompareViewModel

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "tag.fill")
                    .foregroundColor(.orange)
                    .font(.caption)
                Text(group.displayName)
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)
            }

            Divider()

            ForEach(compareVM.priceResults) { res in
                if res.error == nil {
                    let matching = compareVM.findMatchingIAP(in: res, for: group)
                    HStack {
                        Text(res.storefront.flag)
                            .font(.body)
                        Text(res.storefront.name)
                            .font(.subheadline)
                        Spacer()
                        if let iap = matching {
                            Text(iap.formattedPrice)
                                .font(.subheadline.bold())
                                .foregroundColor(.orange)
                        } else {
                            Text("—")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
