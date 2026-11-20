import Foundation

// MARK: - iTunes API Models

/// A single app result from the iTunes Search/Lookup API
public struct AppResult: Identifiable, Codable, Hashable {
    public let trackId: Int
    public let trackName: String
    public let bundleId: String?
    public let artworkUrl100: String?
    public let artworkUrl512: String?
    public let sellerName: String?
    public let formattedPrice: String?
    public let price: Double?
    public let currency: String?
    public let description: String?
    public let averageUserRating: Double?
    public let userRatingCount: Int?
    public let version: String?
    public let fileSizeBytes: String?
    public let primaryGenreName: String?

    public var id: Int { trackId }

    public var artworkURL: URL? {
        if let str = artworkUrl512, let url = URL(string: str) { return url }
        if let str = artworkUrl100, let url = URL(string: str) { return url }
        return nil
    }

    public var iconURL: URL? {
        if let str = artworkUrl100, let url = URL(string: str) { return url }
        return nil
    }

    public var formattedFileSize: String {
        guard let bytesStr = fileSizeBytes, let bytes = Int64(bytesStr) else { return "N/A" }
        return ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
}

/// Wrapper for iTunes Search API response
public struct SearchResponse: Codable {
    public let resultCount: Int
    public let results: [AppResult]
}

// MARK: - In-App Purchase

public struct InAppPurchase: Identifiable, Hashable {
    public let id: UUID
    public let name: String
    public let formattedPrice: String
    public let priceValue: Double?
    public let currency: String

    public init(
        id: UUID = UUID(),
        name: String,
        formattedPrice: String,
        priceValue: Double? = nil,
        currency: String = ""
    ) {
        self.id = id
        self.name = name
        self.formattedPrice = formattedPrice
        self.priceValue = priceValue
        self.currency = currency
    }
}

// MARK: - Country / Storefront

public struct Storefront: Identifiable, Hashable, Codable {
    public let code: String       // ISO 3166-1 alpha-2, e.g. "US"
    public let name: String       // "United States"
    public let flag: String       // 🇺🇸
    public let currencyCode: String  // "USD"

    public var id: String { code }

    public init(code: String, name: String, flag: String, currencyCode: String) {
        self.code = code
        self.name = name
        self.flag = flag
        self.currencyCode = currencyCode
    }
}

// MARK: - Price Comparison Result

public struct PriceResult: Identifiable, Hashable {
    public let id: UUID
    public let storefront: Storefront
    public let appPrice: String?
    public let iapPrices: [IAPComparison]
    public let currency: String
    public let isLoading: Bool
    public let error: String?

    public init(
        id: UUID = UUID(),
        storefront: Storefront,
        appPrice: String?,
        iapPrices: [IAPComparison],
        currency: String,
        isLoading: Bool = false,
        error: String? = nil
    ) {
        self.id = id
        self.storefront = storefront
        self.appPrice = appPrice
        self.iapPrices = iapPrices
        self.currency = currency
        self.isLoading = isLoading
        self.error = error
    }
}

public struct IAPComparison: Identifiable, Hashable {
    public let id: UUID
    public let name: String
    public let formattedPrice: String
    public let priceValue: Double?
    public let usdEquivalent: Double?

    public init(
        id: UUID = UUID(),
        name: String,
        formattedPrice: String,
        priceValue: Double? = nil,
        usdEquivalent: Double? = nil
    ) {
        self.id = id
        self.name = name
        self.formattedPrice = formattedPrice
        self.priceValue = priceValue
        self.usdEquivalent = usdEquivalent
    }
}

// MARK: - Predefined Storefronts

public struct StorefrontCatalog {
    public static let all: [Storefront] = [
        Storefront(code: "US", name: "United States", flag: "🇺🇸", currencyCode: "USD"),
        Storefront(code: "CA", name: "Canada", flag: "🇨🇦", currencyCode: "CAD"),
        Storefront(code: "TR", name: "Turkey", flag: "🇹🇷", currencyCode: "TRY"),
        Storefront(code: "GB", name: "United Kingdom", flag: "🇬🇧", currencyCode: "GBP"),
        Storefront(code: "IN", name: "India", flag: "🇮🇳", currencyCode: "INR"),
        Storefront(code: "BR", name: "Brazil", flag: "🇧🇷", currencyCode: "BRL"),
        Storefront(code: "RU", name: "Russia", flag: "🇷🇺", currencyCode: "RUB"),
        Storefront(code: "EG", name: "Egypt", flag: "🇪🇬", currencyCode: "EGP"),
        Storefront(code: "NG", name: "Nigeria", flag: "🇳🇬", currencyCode: "NGN"),
        Storefront(code: "PK", name: "Pakistan", flag: "🇵🇰", currencyCode: "PKR"),
        Storefront(code: "AR", name: "Argentina", flag: "🇦🇷", currencyCode: "ARS"),
        Storefront(code: "CO", name: "Colombia", flag: "🇨🇴", currencyCode: "COP"),
        Storefront(code: "MX", name: "Mexico", flag: "🇲🇽", currencyCode: "MXN"),
        Storefront(code: "JP", name: "Japan", flag: "🇯🇵", currencyCode: "JPY"),
        Storefront(code: "KR", name: "South Korea", flag: "🇰🇷", currencyCode: "KRW"),
        Storefront(code: "CN", name: "China", flag: "🇨🇳", currencyCode: "CNY"),
        Storefront(code: "TW", name: "Taiwan", flag: "🇹🇼", currencyCode: "TWD"),
        Storefront(code: "AU", name: "Australia", flag: "🇦🇺", currencyCode: "AUD"),
        Storefront(code: "DE", name: "Germany", flag: "🇩🇪", currencyCode: "EUR"),
        Storefront(code: "FR", name: "France", flag: "🇫🇷", currencyCode: "EUR"),
        Storefront(code: "IT", name: "Italy", flag: "🇮🇹", currencyCode: "EUR"),
        Storefront(code: "ES", name: "Spain", flag: "🇪🇸", currencyCode: "EUR"),
        Storefront(code: "NL", name: "Netherlands", flag: "🇳🇱", currencyCode: "EUR"),
        Storefront(code: "SE", name: "Sweden", flag: "🇸🇪", currencyCode: "SEK"),
        Storefront(code: "NO", name: "Norway", flag: "🇳🇴", currencyCode: "NOK"),
        Storefront(code: "DK", name: "Denmark", flag: "🇩🇰", currencyCode: "DKK"),
        Storefront(code: "PL", name: "Poland", flag: "🇵🇱", currencyCode: "PLN"),
        Storefront(code: "CZ", name: "Czech Republic", flag: "🇨🇿", currencyCode: "CZK"),
        Storefront(code: "HU", name: "Hungary", flag: "🇭🇺", currencyCode: "HUF"),
        Storefront(code: "RO", name: "Romania", flag: "🇷🇴", currencyCode: "RON"),
        Storefront(code: "ZA", name: "South Africa", flag: "🇿🇦", currencyCode: "ZAR"),
        Storefront(code: "AE", name: "United Arab Emirates", flag: "🇦🇪", currencyCode: "AED"),
        Storefront(code: "SA", name: "Saudi Arabia", flag: "🇸🇦", currencyCode: "SAR"),
        Storefront(code: "IL", name: "Israel", flag: "🇮🇱", currencyCode: "ILS"),
        Storefront(code: "PH", name: "Philippines", flag: "🇵🇭", currencyCode: "PHP"),
        Storefront(code: "TH", name: "Thailand", flag: "🇹🇭", currencyCode: "THB"),
        Storefront(code: "MY", name: "Malaysia", flag: "🇲🇾", currencyCode: "MYR"),
        Storefront(code: "ID", name: "Indonesia", flag: "🇮🇩", currencyCode: "IDR"),
        Storefront(code: "VN", name: "Vietnam", flag: "🇻🇳", currencyCode: "VND"),
        Storefront(code: "CL", name: "Chile", flag: "🇨🇱", currencyCode: "CLP"),
        Storefront(code: "PE", name: "Peru", flag: "🇵🇪", currencyCode: "PEN"),
        Storefront(code: "UA", name: "Ukraine", flag: "🇺🇦", currencyCode: "UAH"),
        Storefront(code: "KZ", name: "Kazakhstan", flag: "🇰🇿", currencyCode: "KZT"),
        Storefront(code: "HK", name: "Hong Kong", flag: "🇭🇰", currencyCode: "HKD"),
        Storefront(code: "SG", name: "Singapore", flag: "🇸🇬", currencyCode: "SGD"),
        Storefront(code: "NZ", name: "New Zealand", flag: "🇳🇿", currencyCode: "NZD"),
        Storefront(code: "CH", name: "Switzerland", flag: "🇨🇭", currencyCode: "CHF"),
    ]

    /// Quick defaults for comparison
    public static let popularDefaults: [Storefront] = {
        let codes: Set<String> = ["US", "CA", "TR", "IN", "GB", "EG", "BR", "AR"]
        return all.filter { codes.contains($0.code) }
            .sorted { a, b in
                let order = ["US", "CA", "TR", "IN", "GB", "EG", "BR", "AR"]
                return (order.firstIndex(of: a.code) ?? 99) < (order.firstIndex(of: b.code) ?? 99)
            }
    }()
}
