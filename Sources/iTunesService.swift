import Foundation

// MARK: - iTunes Search & App Store Service

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

    // MARK: - Scrape In-App Purchases from App Store Web Page

    /// Fetch In-App Purchases for an app in a specific country storefront by scraping the public App Store page.
    public func fetchIAPs(trackId: Int, country: String, defaultCurrency: String) async -> [InAppPurchase] {
        let countryCode = country.lowercased()
        guard let url = URL(string: "https://apps.apple.com/\(countryCode)/app/id\(trackId)") else {
            return []
        }

        var request = URLRequest(url: url)
        // Desktop User-Agent prevents Apple from redirecting to itms-appss://
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36", forHTTPHeaderField: "User-Agent")
        request.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")
        request.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 12

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                return []
            }
            guard let html = String(data: data, encoding: .utf8) else {
                return []
            }
            return parseIAPs(from: html, defaultCurrency: defaultCurrency)
        } catch {
            return []
        }
    }

    // MARK: - Parse IAPs from HTML

    private func parseIAPs(from html: String, defaultCurrency: String) -> [InAppPurchase] {
        var rawPairs: [(name: String, price: String)] = []

        // Pattern 1: Rendered HTML list items: <div class="text-pair..."><span>Name</span> <span>Price</span></div>
        let pattern1 = #"class="text-pair[^"]*">\s*<span>(.*?)</span>\s*<span>(.*?)</span>\s*</div>"#

        // Pattern 2: JSON data embedded in page: "leadingText":"Name","trailingText":"Price"
        let pattern2 = #""leadingText":"([^"]+)","trailingText":"([^"]+)""#

        let patterns = [pattern1, pattern2]

        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) else {
                continue
            }

            let nsRange = NSRange(html.startIndex..<html.endIndex, in: html)
            let matches = regex.matches(in: html, options: [], range: nsRange)

            if !matches.isEmpty {
                for match in matches {
                    guard match.numberOfRanges >= 3,
                          let nameRange = Range(match.range(at: 1), in: html),
                          let priceRange = Range(match.range(at: 2), in: html) else {
                        continue
                    }

                    let rawName = String(html[nameRange])
                    let rawPrice = String(html[priceRange])

                    let name = cleanHTMLEntities(rawName)
                    let price = cleanHTMLEntities(rawPrice)

                    guard !name.isEmpty, !price.isEmpty else { continue }
                    rawPairs.append((name, price))
                }

                if !rawPairs.isEmpty {
                    break
                }
            }
        }

        // Process and deduplicate exact duplicate (name, price) pairs while preserving distinct tiers
        var results: [InAppPurchase] = []
        var seenExact = Set<String>()
        var nameCounts: [String: Int] = [:]

        for pair in rawPairs {
            let exactKey = "\(pair.name.lowercased())|\(pair.price)"
            if seenExact.contains(exactKey) {
                // Skip identical duplicates (e.g. YouTube Premium $20.99 listed 4 times)
                continue
            }
            seenExact.insert(exactKey)

            let normName = pair.name.lowercased()
            let count = nameCounts[normName, default: 0]
            nameCounts[normName] = count + 1

            let isAnnualKeyword = pair.name.localizedCaseInsensitiveContains("annual") ||
                                 pair.name.localizedCaseInsensitiveContains("year")
            let isTier2 = count > 0 || isAnnualKeyword

            results.append(InAppPurchase(
                name: pair.name,
                formattedPrice: pair.price,
                priceValue: nil,
                currency: defaultCurrency,
                isAnnualOrTier2: isTier2
            ))
        }

        return results
    }

    private func cleanHTMLEntities(_ string: String) -> String {
        var s = string
        s = s.replacingOccurrences(of: "&amp;", with: "&")
        s = s.replacingOccurrences(of: "&#39;", with: "'")
        s = s.replacingOccurrences(of: "&quot;", with: "\"")
        s = s.replacingOccurrences(of: "&lt;", with: "<")
        s = s.replacingOccurrences(of: "&gt;", with: ">")
        s = s.replacingOccurrences(of: "&nbsp;", with: " ")
        s = s.replacingOccurrences(of: "\u{00A0}", with: " ")
        s = s.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Multi-Storefront Comparison

    /// Look up an app across multiple storefronts concurrently with a worker pool (max 3 at a time)
    /// to avoid getting rate-limited by Apple servers.
    public func compareAcrossStorefronts(
        trackId: Int,
        storefronts: [Storefront]
    ) -> AsyncStream<PriceResult> {
        AsyncStream { continuation in
            Task {
                let maxConcurrent = 3
                var index = 0
                let total = storefronts.count

                await withTaskGroup(of: PriceResult.self) { group in
                    while index < min(maxConcurrent, total) {
                        let sf = storefronts[index]
                        index += 1
                        group.addTask {
                            await self.fetchStorefrontData(trackId: trackId, storefront: sf)
                        }
                    }

                    for await result in group {
                        continuation.yield(result)

                        if index < total {
                            let nextSf = storefronts[index]
                            index += 1
                            group.addTask {
                                await self.fetchStorefrontData(trackId: trackId, storefront: nextSf)
                            }
                        }
                    }
                }
                continuation.finish()
            }
        }
    }

    private func fetchStorefrontData(trackId: Int, storefront: Storefront) async -> PriceResult {
        // 1. Fetch official iTunes metadata (App price, currency, rating, etc.)
        var app: AppResult?
        do {
            app = try await lookupApp(trackId: trackId, country: storefront.code)
        } catch {
            // Non-fatal
        }

        // 2. Fetch IAP prices from web page
        let iaps = await fetchIAPs(trackId: trackId, country: storefront.code, defaultCurrency: storefront.currencyCode)

        // 3. Handle unavailable apps
        if app == nil && iaps.isEmpty {
            return PriceResult(
                storefront: storefront,
                appPrice: nil,
                iapPrices: [],
                currency: storefront.currencyCode,
                isLoading: false,
                error: "Not available in \(storefront.name)"
            )
        }

        let iapComparisons = iaps.map { iap in
            IAPComparison(
                name: iap.name,
                formattedPrice: iap.formattedPrice,
                priceValue: iap.priceValue,
                usdEquivalent: nil,
                isAnnualOrTier2: iap.isAnnualOrTier2
            )
        }

        return PriceResult(
            storefront: storefront,
            appPrice: app?.formattedPrice ?? (app != nil ? "Free" : "Available"),
            iapPrices: iapComparisons,
            currency: app?.currency ?? storefront.currencyCode,
            isLoading: false,
            error: nil
        )
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
