import Foundation

final class ProfileService {
    private let api = APIClient.shared

    func updateUsername(token: String, username: String) async throws -> User {
        let body = UpdateUsernameRequest(display_name: username)

        let response: User = try await api.request(
            path: "/profile/username",
            method: "POST",
            token: token,
            body: body
        )
        return response
    }
}

struct UpdateUsernameRequest: Encodable {
    let display_name: String
}
