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

        let storefrontsToQuery = selectedStorefronts

        compareTask = Task {
            let stream = iTunesService.shared.compareAcrossStorefronts(
                trackId: app.trackId,
                storefronts: storefrontsToQuery
            )

            for await result in stream {
                if Task.isCancelled { break }
                self.priceResults.append(result)
                self.progress += 1

                let sfOrder = Dictionary(uniqueKeysWithValues: storefrontsToQuery.enumerated().map { ($1.code, $0) })
                self.priceResults.sort { a, b in
                    (sfOrder[a.storefront.code] ?? 999) < (sfOrder[b.storefront.code] ?? 999)
                }
            }

            self.isLoading = false
        }
    }

    public func cancel() {
        compareTask?.cancel()
        isLoading = false
    }

    // MARK: - Smart Comparison Groups

    /// Generates unified comparison groups across all storefronts using normalized matching
    public var comparisonGroups: [IAPGroup] {
        var groups: [IAPGroup] = []
        var seenKeys = Set<String>()

        for result in priceResults {
            for iap in result.iapPrices {
                let baseKey = normalizeName(iap.name)
                let groupKey = iap.isAnnualOrTier2 ? "\(baseKey)_tier2" : "\(baseKey)_tier1"

                if !seenKeys.contains(groupKey) {
                    seenKeys.insert(groupKey)

                    var display = iap.name
                    if iap.isAnnualOrTier2 && !display.localizedCaseInsensitiveContains("annual") && !display.localizedCaseInsensitiveContains("year") {
                        display = "\(display) (Tier 2 / Annual)"
                    }

                    groups.append(IAPGroup(
                        key: groupKey,
                        displayName: display,
                        isAnnualOrTier2: iap.isAnnualOrTier2
                    ))
                }
            }
        }

        return groups
    }

    /// Finds the best matching IAP in a storefront for a given comparison group
    public func findMatchingIAP(in result: PriceResult, for group: IAPGroup) -> IAPComparison? {
        let targetBase = group.key.replacingOccurrences(of: "_tier1", with: "").replacingOccurrences(of: "_tier2", with: "")

        // 1. Try exact match with tier
        for iap in result.iapPrices {
            let base = normalizeName(iap.name)
            if base == targetBase && iap.isAnnualOrTier2 == group.isAnnualOrTier2 {
                return iap
            }
        }

        // 2. Try match on base key
        for iap in result.iapPrices {
            let base = normalizeName(iap.name)
            if base == targetBase {
                return iap
            }
        }

        return nil
    }

    /// Helper to normalize names (e.g. "YouTube Premium" -> "youtube premium", "100 GB Month" -> "100 gb")
    private func normalizeName(_ name: String) -> String {
        var s = name.trimmingCharacters(in: .whitespacesAndNewlines)
        s = s.replacingOccurrences(of: "\\(.*?\\)", with: "", options: .regularExpression)
        s = s.replacingOccurrences(of: "\\b(month|monthly|annual|year|yearly|paket[i]?)\\b", with: "", options: [.caseInsensitive, .regularExpression])
        s = s.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        s = s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return s.count > 1 ? s : name.lowercased()
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
