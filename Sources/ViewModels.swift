import SwiftUI
import Combine

// MARK: - Search View Model

@MainActor
public final class SearchViewModel: ObservableObject {
    @Published public var query: String = ""
    @Published public var results: [AppResult] = []
    @Published public var isSearching: Bool = false
    @Published public var errorMessage: String?
    @Published public var searchCountry: String = "US"

    private var searchTask: Task<Void, Never>?

    public init() {}

    public func search() {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            results = []
            return
        }

        searchTask?.cancel()
        isSearching = true
        errorMessage = nil

        searchTask = Task {
            do {
                let apps = try await iTunesService.shared.searchApps(
                    query: trimmed,
                    country: searchCountry,
                    limit: 30
                )
                if !Task.isCancelled {
                    self.results = apps
                    self.isSearching = false
                }
            } catch {
                if !Task.isCancelled {
                    self.errorMessage = error.localizedDescription
                    self.isSearching = false
                }
            }
        }
    }
}

// MARK: - Price Comparison View Model

@MainActor
public final class CompareViewModel: ObservableObject {
    @Published public var app: AppResult
    @Published public var selectedStorefronts: [Storefront]
    @Published public var priceResults: [PriceResult] = []
    @Published public var isLoading: Bool = false
    @Published public var progress: Int = 0
    @Published public var total: Int = 0

    private var compareTask: Task<Void, Never>?

    public init(app: AppResult, storefronts: [Storefront]? = nil) {
        self.app = app
        self.selectedStorefronts = storefronts ?? StorefrontCatalog.popularDefaults
    }

    public func startComparison() {
        compareTask?.cancel()
        priceResults = []
        isLoading = true
        progress = 0
        total = selectedStorefronts.count

        compareTask = Task {
            let stream = iTunesService.shared.compareAcrossStorefronts(
                trackId: app.trackId,
                storefronts: selectedStorefronts
            )

            for await result in stream {
                if Task.isCancelled { break }
                self.priceResults.append(result)
                self.progress += 1

                // Sort: cheapest app price first, errors at bottom
                self.priceResults.sort { a, b in
                    if a.error != nil && b.error == nil { return false }
                    if a.error == nil && b.error != nil { return true }
                    // Sort by storefront name as default
                    return a.storefront.name < b.storefront.name
                }
            }

            self.isLoading = false
        }
    }

    public func cancel() {
        compareTask?.cancel()
        isLoading = false
    }

    /// All unique IAP names across all storefronts
    public var allIAPNames: [String] {
        var seen = Set<String>()
        var names: [String] = []
        for result in priceResults {
            for iap in result.iapPrices {
                if seen.insert(iap.name).inserted {
                    names.append(iap.name)
                }
            }
        }
        return names
    }
}

// MARK: - Settings / Favorites

@MainActor
public final class SettingsViewModel: ObservableObject {
    @Published public var favoriteStorefronts: [Storefront] {
        didSet { saveFavorites() }
    }

    private let favoritesKey = "PriceTag_FavoriteStorefronts"

    public init() {
        if let data = UserDefaults.standard.data(forKey: "PriceTag_FavoriteStorefronts"),
           let saved = try? JSONDecoder().decode([Storefront].self, from: data) {
            self.favoriteStorefronts = saved
        } else {
            self.favoriteStorefronts = StorefrontCatalog.popularDefaults
        }
    }

    public func saveFavorites() {
        if let data = try? JSONEncoder().encode(favoriteStorefronts) {
            UserDefaults.standard.set(data, forKey: favoritesKey)
        }
    }

    public func toggleStorefront(_ sf: Storefront) {
        if let idx = favoriteStorefronts.firstIndex(of: sf) {
            favoriteStorefronts.remove(at: idx)
        } else {
            favoriteStorefronts.append(sf)
        }
    }

    public func isFavorite(_ sf: Storefront) -> Bool {
        favoriteStorefronts.contains(sf)
    }
}
