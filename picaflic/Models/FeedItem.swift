import Foundation

struct FeedItem: Decodable, Identifiable {
    let localId: Int?
    let tmdb_id: Int
    let is_tv: Int
    let title: String
    let popularity: Double
    let release_date: String?
    let poster_path: String?

    enum CodingKeys: String, CodingKey {
        case localId = "id"
        case tmdb_id
        case is_tv
        case title
        case popularity
        case release_date
        case poster_path
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.localId = try container.decodeFlexibleIntIfPresent(forKey: .localId)
        self.tmdb_id = try container.decodeFlexibleInt(forKey: .tmdb_id)
        self.is_tv = try container.decodeFlexibleInt(forKey: .is_tv)
        self.title = try container.decode(String.self, forKey: .title)
        self.popularity = try container.decodeFlexibleDoubleIfPresent(forKey: .popularity) ?? 0
        self.release_date = try container.decodeIfPresent(String.self, forKey: .release_date)
        self.poster_path = try container.decodeIfPresent(String.self, forKey: .poster_path)
    }

    var id: String {
        "\(is_tv)-\(tmdb_id)"
    }

    var isTV: Bool {
        is_tv == 1
    }

    var posterURL: URL? {
        guard let poster_path, !poster_path.isEmpty else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w500\(poster_path)")
    }
}

private extension KeyedDecodingContainer where K == FeedItem.CodingKeys {
    func decodeFlexibleInt(forKey key: K) throws -> Int {
        if let intValue = try? decode(Int.self, forKey: key) {
            return intValue
        }

        if let stringValue = try? decode(String.self, forKey: key),
           let intValue = Int(stringValue) {
            return intValue
        }

        throw DecodingError.typeMismatch(
            Int.self,
            DecodingError.Context(
                codingPath: codingPath + [key],
                debugDescription: "Expected Int or numeric String for \(key.stringValue)"
            )
        )
    }

    func decodeFlexibleIntIfPresent(forKey key: K) throws -> Int? {
        if let intValue = try decodeIfPresent(Int.self, forKey: key) {
            return intValue
        }

        if let stringValue = try decodeIfPresent(String.self, forKey: key) {
            return Int(stringValue)
        }

        return nil
    }

    func decodeFlexibleDoubleIfPresent(forKey key: K) throws -> Double? {
        if let doubleValue = try decodeIfPresent(Double.self, forKey: key) {
            return doubleValue
        }

        if let intValue = try decodeIfPresent(Int.self, forKey: key) {
            return Double(intValue)
        }

        if let stringValue = try decodeIfPresent(String.self, forKey: key) {
            let trimmed = stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                return nil
            }
            return Double(trimmed)
        }

        return nil
    }
}
