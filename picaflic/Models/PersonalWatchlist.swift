import Foundation

struct PersonalWatchlist: Decodable, Identifiable {
    let id: Int
    let name: String
    let movie_count: Int
}

struct PersonalWatchlistsResponse: Decodable {
    let results: [PersonalWatchlist]
}
