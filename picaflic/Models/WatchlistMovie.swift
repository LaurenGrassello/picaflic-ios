import Foundation

struct WatchlistMovie: Decodable, Identifiable, Hashable {
    let id: Int
    let title: String?
    let tmdb_id: Int?
    let poster_path: String?

    var posterURL: URL? {
        guard let poster_path, !poster_path.isEmpty else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w500\(poster_path)")
    }
}

struct WatchlistMoviesResponse: Decodable {
    let results: [WatchlistMovie]
}
