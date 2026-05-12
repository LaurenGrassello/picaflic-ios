import Foundation

struct StreamingServiceItem: Decodable, Identifiable, Hashable {
    let id: Int
    let name: String
}

struct StreamingServicesResponse: Decodable {
    let results: [StreamingServiceItem]
}

struct UserStreamingServicesResponse: Decodable {
    let provider_ids: [Int]
}

struct UpdateStreamingServicesRequest: Encodable {
    let provider_ids: [Int]
}

struct UpdateStreamingServicesResponse: Decodable {
    let ok: Bool
    let provider_ids: [Int]
}
