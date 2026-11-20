import SwiftUI

public struct AppDetailView: View {
    public let app: AppResult
    @StateObject private var compareVM: CompareViewModel
    @EnvironmentObject private var settingsVM: SettingsViewModel
    @State private var showStorefrontPicker = false

    public init(app: AppResult) {
        self.app = app
        _compareVM = StateObject(wrappedValue: CompareViewModel(app: app))
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                appHeader
                actionButtons
                comparisonSection
            }
            .padding()
        }
        .navigationTitle("Compare Prices")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            compareVM.selectedStorefronts = settingsVM.favoriteStorefronts
        }
        .sheet(isPresented: $showStorefrontPicker) {
            StorefrontSelectionSheet(
                selectedStorefronts: $compareVM.selectedStorefronts
            )
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
                compareVM.selectedStorefronts = settingsVM.favoriteStorefronts
                compareVM.startComparison()
            } label: {
                Label(compareVM.isLoading ? "Comparing..." : "Compare Prices", systemImage: "arrow.triangle.2.circlepath")
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            .disabled(compareVM.isLoading || compareVM.selectedStorefronts.isEmpty)
        }
    }

    // MARK: - Comparison Results

    private var comparisonSection: some View {
        VStack(spacing: 12) {
            if compareVM.isLoading {
                VStack(spacing: 8) {
                    ProgressView(value: Double(compareVM.progress), total: Double(compareVM.total))
                        .tint(.orange)
                    Text("Checking \(compareVM.progress)/\(compareVM.total) storefronts...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            }

            if !compareVM.priceResults.isEmpty {
                // App price comparison
                appPriceSection

                // IAP comparison
                if !compareVM.allIAPNames.isEmpty {
                    iapSection
                }
            }
        }
    }

    // MARK: - App Price Section

    private var appPriceSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("App Price", systemImage: "dollarsign.circle.fill")
                .font(.headline)
                .foregroundColor(.primary)

            ForEach(compareVM.priceResults) { result in
                if result.error == nil {
                    HStack {
                        Text(result.storefront.flag)
                            .font(.title3)
                        Text(result.storefront.name)
                            .font(.subheadline)
                        Spacer()
                        Text(result.appPrice ?? "N/A")
                            .font(.subheadline.bold())
                            .foregroundColor(result.appPrice == "Free" ? .green : .primary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                } else {
                    HStack {
                        Text(result.storefront.flag)
                            .font(.title3)
                        Text(result.storefront.name)
                            .font(.subheadline)
                        Spacer()
                        Text("Error")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .opacity(0.6)
                }
            }
        }
    }

    // MARK: - IAP Section

    private var iapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("In-App Purchases", systemImage: "creditcard.fill")
                .font(.headline)
                .foregroundColor(.primary)

            ForEach(compareVM.allIAPNames, id: \.self) { iapName in
                IAPComparisonCard(
                    iapName: iapName,
                    results: compareVM.priceResults
                )
            }
        }
    }
}

// MARK: - IAP Comparison Card

public struct IAPComparisonCard: View {
    public let iapName: String
    public let results: [PriceResult]

    private var iapRows: [(storefront: Storefront, iap: IAPComparison?)] {
        results.compactMap { result in
            guard result.error == nil else { return nil }
            let matching = result.iapPrices.first { $0.name == iapName }
            return (storefront: result.storefront, iap: matching)
        }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(iapName)
                .font(.subheadline.bold())
                .foregroundColor(.orange)

            ForEach(Array(iapRows.enumerated()), id: \.offset) { _, row in
                HStack {
                    Text(row.storefront.flag)
                    Text(row.storefront.code)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 28, alignment: .leading)
                    Spacer()
                    if let iap = row.iap {
                        Text(iap.formattedPrice)
                            .font(.subheadline.bold())
                    } else {
                        Text("Not available")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
