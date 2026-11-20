import SwiftUI

public struct SearchView: View {
    @StateObject private var vm = SearchViewModel()
    @EnvironmentObject private var settingsVM: SettingsViewModel

    public init() {}

    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                searchBar

                // Results
                if vm.isSearching {
                    Spacer()
                    ProgressView("Searching...")
                        .padding()
                    Spacer()
                } else if let error = vm.errorMessage {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Retry") { vm.search() }
                            .buttonStyle(.borderedProminent)
                            .tint(.orange)
                    }
                    .padding()
                    Spacer()
                } else if vm.results.isEmpty && !vm.query.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "app.dashed")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No apps found")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else if vm.results.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "tag.fill")
                            .font(.system(size: 56))
                            .foregroundColor(.orange)
                        Text("PriceTag")
                            .font(.largeTitle.bold())
                        Text("Search for any app to compare\nin-app purchase prices worldwide")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    Spacer()
                } else {
                    resultsList
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(.stack)
    }

    // MARK: - Search Bar
    private var searchBar: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search apps...", text: $vm.query)
                    .textFieldStyle(.plain)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .submitLabel(.search)
                    .onSubmit { vm.search() }

                if !vm.query.isEmpty {
                    Button {
                        vm.query = ""
                        vm.results = []
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(10)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
            .padding(.top, 8)
        }
    }

    // MARK: - Results List
    private var resultsList: some View {
        List(vm.results) { app in
            NavigationLink {
                AppDetailView(app: app)
                    .environmentObject(settingsVM)
            } label: {
                AppRowView(app: app)
            }
        }
        .listStyle(.plain)
    }
}

// MARK: - App Row

public struct AppRowView: View {
    public let app: AppResult

    public var body: some View {
        HStack(spacing: 12) {
            // App icon
            AsyncImage(url: app.iconURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray5))
                        .overlay(
                            Image(systemName: "app.fill")
                                .foregroundColor(.secondary)
                        )
                default:
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray5))
                        .overlay(ProgressView())
                }
            }
            .frame(width: 52, height: 52)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 3) {
                Text(app.trackName)
                    .font(.headline)
                    .lineLimit(1)

                if let seller = app.sellerName {
                    Text(seller)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                HStack(spacing: 6) {
                    if let price = app.formattedPrice {
                        Text(price)
                            .font(.caption.bold())
                            .foregroundColor(price == "Free" ? .green : .orange)
                    }

                    if let genre = app.primaryGenreName {
                        Text("·")
                            .foregroundColor(.secondary)
                        Text(genre)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}
