import Foundation

// MARK: - iTunes Search / Lookup Service

public final class iTunesService {
    public static let shared = iTunesService()
    private init() {}

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        return URLSession(configuration: config)
    }()

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        return d
    }()

    // MARK: - Search

    /// Search the iTunes store for apps matching a query in a given country
    public func searchApps(query: String, country: String = "US", limit: Int = 25) async throws -> [AppResult] {
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw ServiceError.invalidQuery
        }

        let urlString = "https://itunes.apple.com/search?term=\(encoded)&country=\(country)&entity=software&limit=\(limit)"
        guard let url = URL(string: urlString) else {
            throw ServiceError.invalidURL
        }

        let (data, response) = try await session.data(from: url)
        try validateResponse(response)

        let result = try decoder.decode(SearchResponse.self, from: data)
        return result.results
    }

    // MARK: - Lookup by ID

    /// Look up a specific app by its track ID in a given country storefront
    public func lookupApp(trackId: Int, country: String = "US") async throws -> AppResult? {
        let urlString = "https://itunes.apple.com/lookup?id=\(trackId)&country=\(country)"
        guard let url = URL(string: urlString) else {
            throw ServiceError.invalidURL
        }

        let (data, response) = try await session.data(from: url)
        try validateResponse(response)

        let result = try decoder.decode(SearchResponse.self, from: data)
        return result.results.first
    }

    // MARK: - Lookup with IAPs

    /// Look up an app including its in-app purchases in a given storefront.
    /// The iTunes API returns IAPs as separate results with wrapperType "software" kind "in-app-purchase"
    /// when using `entity=software,inApp` or by scraping the app page.
    /// We use the lookup endpoint which returns IAP info in `iapItems`.
    public func lookupAppWithIAPs(trackId: Int, country: String = "US") async throws -> (app: AppResult?, iaps: [InAppPurchase]) {
        // The lookup endpoint with software entity returns the app
        let urlString = "https://itunes.apple.com/lookup?id=\(trackId)&country=\(country)&entity=inApp"
        guard let url = URL(string: urlString) else {
            throw ServiceError.invalidURL
        }

        let (data, response) = try await session.data(from: url)
        try validateResponse(response)

        // Parse as generic JSON since IAPs come in a mixed format
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let results = json["results"] as? [[String: Any]] else {
            return (nil, [])
        }

        var app: AppResult?
        var iaps: [InAppPurchase] = []

        for item in results {
            let wrapperType = item["wrapperType"] as? String ?? ""

            if wrapperType == "software" {
                // This is the app itself
                if let itemData = try? JSONSerialization.data(withJSONObject: item),
                   let decoded = try? decoder.decode(AppResult.self, from: itemData) {
                    app = decoded
                }
            } else if wrapperType == "in-app-purchase" {
                // This is an IAP
                let name = item["trackName"] as? String ?? "Unknown"
                let formattedPrice = item["formattedPrice"] as? String ?? "N/A"
                let price = item["price"] as? Double
                let currency = item["currency"] as? String ?? "USD"

                iaps.append(InAppPurchase(
                    name: name,
                    formattedPrice: formattedPrice,
                    priceValue: price,
                    currency: currency
                ))
            }
        }

        return (app, iaps)
    }

    // MARK: - Multi-Storefront Comparison

    /// Look up an app across multiple storefronts simultaneously
    public func compareAcrossStorefronts(
        trackId: Int,
        storefronts: [Storefront]
    ) -> AsyncStream<PriceResult> {
        AsyncStream { continuation in
            Task {
                await withTaskGroup(of: PriceResult.self) { group in
                    for sf in storefronts {
                        group.addTask {
                            do {
                                let (app, iaps) = try await self.lookupAppWithIAPs(
                                    trackId: trackId,
                                    country: sf.code
                                )

                                let iapComparisons = iaps.map { iap in
                                    IAPComparison(
                                        name: iap.name,
                                        formattedPrice: iap.formattedPrice,
                                        priceValue: iap.priceValue,
                                        usdEquivalent: nil // Computed later if exchange rates available
                                    )
                                }

                                return PriceResult(
                                    storefront: sf,
                                    appPrice: app?.formattedPrice,
                                    iapPrices: iapComparisons,
                                    currency: app?.currency ?? sf.currencyCode,
                                    isLoading: false,
                                    error: nil
                                )
                            } catch {
                                return PriceResult(
                                    storefront: sf,
                                    appPrice: nil,
                                    iapPrices: [],
                                    currency: sf.currencyCode,
                                    isLoading: false,
                                    error: error.localizedDescription
                                )
                            }
                        }
                    }

                    for await result in group {
                        continuation.yield(result)
                    }
                }
                continuation.finish()
            }
        }
    }

    // MARK: - Helpers

    private func validateResponse(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else {
            throw ServiceError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            if http.statusCode == 403 || http.statusCode == 429 {
                throw ServiceError.rateLimited
            }
            throw ServiceError.httpError(http.statusCode)
        }
    }
}

// MARK: - Service Errors

public enum ServiceError: LocalizedError {
    case invalidQuery
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case rateLimited
    case decodingError(String)

    public var errorDescription: String? {
        switch self {
        case .invalidQuery: return "Invalid search query"
        case .invalidURL: return "Could not build request URL"
        case .invalidResponse: return "Invalid server response"
        case .httpError(let code): return "Server error (HTTP \(code))"
        case .rateLimited: return "Rate limited — try again shortly"
        case .decodingError(let msg): return "Data error: \(msg)"
        }
    }
}
