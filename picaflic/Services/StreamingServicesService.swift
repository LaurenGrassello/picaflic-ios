import Foundation

final class StreamingServicesService {
    private let api = APIClient.shared

    func fetchAvailableServices(token: String) async throws -> [StreamingServiceItem] {
        let response: StreamingServicesResponse = try await api.request(
            path: "/streaming-services",
            token: token
        )
        return response.results
    }

    func fetchMyServices(token: String) async throws -> [Int] {
        let response: UserStreamingServicesResponse = try await api.request(
            path: "/profile/streaming-services",
            token: token
        )
        return response.provider_ids
    }

    func saveMyServices(token: String, providerIds: [Int]) async throws -> [Int] {
        let body = UpdateStreamingServicesRequest(provider_ids: providerIds)

        let response: UpdateStreamingServicesResponse = try await api.request(
            path: "/profile/streaming-services",
            method: "POST",
            token: token,
            body: body
        )
        return response.provider_ids
    }
}
