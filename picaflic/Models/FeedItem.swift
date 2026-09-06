import Foundation

struct FeedItem: Decodable, Identifiable, Hashable {
    let id: Int?
    let tmdb_id: Int
    let is_tv: Int
    let title: String
    let popularity: Double?
    let release_date: String?
    let poster_path: String?
    let provider_ids: String?     // comma-separated, e.g. "8,15,337"
    let provider_names: String?   // pipe-separated, e.g. "Netflix|Hulu|Disney Plus"
    let genre_ids: String?        // comma-separated e.g. "28,12,878"

    var localId: Int? { id }
    var isTV: Bool { is_tv == 1 }

    var posterURL: URL? {
        guard let poster_path, !poster_path.isEmpty else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w500\(poster_path)")
    }

    var genreIdList: [Int] {
        guard let genre_ids else { return [] }
        return genre_ids.split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
    }

    // TMDb genre ID map
    var genreNames: [String] {
        genreIdList.compactMap { Self.tmdbGenreMap[$0] }
    }

    static let tmdbGenreMap: [Int: String] = [
        28: "Action", 12: "Adventure", 16: "Animation",
        35: "Comedy", 80: "Crime", 99: "Documentary",
        18: "Drama", 10751: "Family", 14: "Fantasy",
        36: "History", 27: "Horror", 10402: "Music",
        9648: "Mystery", 10749: "Romance", 878: "Sci-Fi",
        10770: "TV Movie", 53: "Thriller", 10752: "War",
        37: "Western"
    ]

    // MARK: - Providers

    var providerIdList: [Int] {
        guard let provider_ids else { return [] }
        return provider_ids.split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
    }

    var providerNameList: [String] {
        guard let provider_names else { return [] }
        return provider_names.split(separator: "|").map { $0.trimmingCharacters(in: .whitespaces) }
    }

    /// Ordered (id, name, asset) tuples for every service this title is on.
    var providers: [(id: Int, name: String, asset: String?)] {
        let ids = providerIdList
        let names = providerNameList
        return ids.enumerated().map { index, pid in
            let name = index < names.count ? names[index] : ""
            return (id: pid, name: name, asset: Self.assetName(for: pid))
        }
    }

    static func assetName(for providerId: Int) -> String? {
        switch providerId {
        case 8:    return "ServiceNetflix"
        case 9:    return "ServicePrimeVideo"
        case 15:   return "ServiceHulu"
        case 73:   return "ServiceTubi"
        case 99:   return "ServiceShudder"
        case 337:  return "ServiceDisneyPlus"
        case 350:  return "ServiceAppleTVPlus"
        case 386:  return "ServicePeacock"
        case 1899: return "ServiceMax"
        default:   return nil
        }
    }
}

struct FeedResultsResponse: Decodable {
    let results: [FeedItem]
}

struct MovieDetails: Decodable {
    let overview: String?
    let release_date: String?
    let runtime: Int?
    let providers: [MovieProvider]?
}

struct MovieProvider: Decodable {
    let name: String?
}
