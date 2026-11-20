# PriceTag 🏷️

**Compare App Store in-app purchase prices across 47+ countries.**

Ever wonder if that $9.99 IAP is cheaper in Turkey or India? PriceTag lets you search for any app and instantly compare its price and all in-app purchases across dozens of App Store storefronts — in their local currencies.

## Features

- 🔍 **Search** — Find any app on the App Store by name
- 🌍 **47+ Countries** — Compare across US, Canada, Turkey, India, Brazil, Argentina, Egypt, UK, Japan, and many more
- 💰 **IAP Prices** — See every in-app purchase listed with its local price per country
- 📊 **Side-by-Side** — All prices shown together so you can spot the cheapest storefront
- ⭐ **Favorites** — Save your preferred countries for quick one-tap comparisons
- 🏷️ **App Price** — Also shows the base app price (Free / Paid) per storefront
- 🚀 **Fast** — Queries all storefronts simultaneously using async/await

## Screenshots

| Search | Compare | Countries |
|--------|---------|-----------|
| Search any app | Side-by-side IAP prices | Pick from 47+ storefronts |

## How It Works

PriceTag uses Apple's public **iTunes Search API** to query app information across different country storefronts:

```
https://itunes.apple.com/lookup?id={APP_ID}&country={COUNTRY_CODE}&entity=inApp
```

Each storefront returns prices in its local currency. The app queries all selected storefronts in parallel and displays the results side-by-side.

**No Apple ID or authentication required.**

## Popular Comparisons

| Country | Flag | Currency | Often Cheaper? |
|---------|------|----------|----------------|
| Turkey | 🇹🇷 | TRY | ✅ Significantly |
| India | 🇮🇳 | INR | ✅ Yes |
| Argentina | 🇦🇷 | ARS | ✅ Yes |
| Brazil | 🇧🇷 | BRL | ✅ Sometimes |
| Egypt | 🇪🇬 | EGP | ✅ Sometimes |
| Pakistan | 🇵🇰 | PKR | ✅ Yes |
| Nigeria | 🇳🇬 | NGN | ✅ Yes |

## Building

### Requirements
- Xcode 15+ (macOS)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)
- [ldid](https://github.com/ProcursusTeam/ldid) (for entitlement signing)

### Build Locally
```bash
brew install xcodegen ldid
chmod +x tools/build-app.sh
./tools/build-app.sh
```

### GitHub Actions
The repo includes a CI workflow that automatically builds `.ipa` and `.tipa` packages on every push to `main`. You can also trigger builds manually via `workflow_dispatch`.

## Installation

| Method | File | Instructions |
|--------|------|-------------|
| **TrollStore** | `PriceTag.tipa` | Open in TrollStore |
| **Sideload** | `PriceTag.ipa` | Use AltStore, Sideloadly, etc. |

## Tech Stack

- **SwiftUI** — Entire UI
- **Async/Await** — Concurrent storefront queries
- **iTunes Search API** — No private APIs, no scraping
- **XcodeGen** — Project generation from `project.yml`
- **iOS 15.0+** — Minimum deployment target

## License

MIT

---

Made with ❤️ by Moe
