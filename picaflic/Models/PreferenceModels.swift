import Foundation

struct PreferenceRequest: Encodable {
    let movie_id: Int
    let status: String
}

struct PreferenceResponse: Decodable {
    let ok: Bool
    let movie_id: Int
    let status: String
}
