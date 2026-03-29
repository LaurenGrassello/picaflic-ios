import Foundation

struct ProviderInfo: Decodable, Identifiable, Hashable {
    let id: Int
    let name: String
    let logo_path: String?

    var logoURL: URL? {
        guard let logo_path, !logo_path.isEmpty else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w200\(logo_path)")
    }
}

struct TitleDetails: Decodable {
    let id: Int?
    let tmdb_id: Int
    let is_tv: Int
    let title: String?
    let release_date: String?
    let poster_path: String?
    let overview: String?
    let providers: [ProviderInfo]

    enum CodingKeys: String, CodingKey {
        case id
        case tmdb_id
        case is_tv
        case title
        case release_date
        case poster_path
        case overview
        case providers
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decodeIfPresent(Int.self, forKey: .id)
        self.tmdb_id = try container.decode(Int.self, forKey: .tmdb_id)
        self.is_tv = try container.decode(Int.self, forKey: .is_tv)
        self.title = try container.decodeIfPresent(String.self, forKey: .title)
        self.release_date = try container.decodeFlexibleStringIfPresent(forKey: .release_date)
        self.poster_path = try container.decodeIfPresent(String.self, forKey: .poster_path)
        self.overview = try container.decodeIfPresent(String.self, forKey: .overview)
        self.providers = try container.decodeIfPresent([ProviderInfo].self, forKey: .providers) ?? []
    }
}

private extension KeyedDecodingContainer where K == TitleDetails.CodingKeys {
    func decodeFlexibleStringIfPresent(forKey key: K) throws -> String? {
        if let stringValue = try decodeIfPresent(String.self, forKey: key) {
            return stringValue
        }

        if let intValue = try decodeIfPresent(Int.self, forKey: key) {
            return String(intValue)
        }

        if let doubleValue = try decodeIfPresent(Double.self, forKey: key) {
            return String(doubleValue)
        }

        return nil
    }
}
