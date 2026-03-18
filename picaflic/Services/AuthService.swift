import Foundation

final class AuthService {
    private let api = APIClient.shared

    func login(email: String, password: String) async throws -> AuthResponse {
        let request = LoginRequest(email: email, password: password)
        let response: AuthResponse = try await api.request(
            path: "/auth/login",
            method: "POST",
            body: request
        )
        return response
    }

    func register(email: String, password: String, displayName: String, services: [String]) async throws {
        let request = RegisterRequest(
            email: email,
            password: password,
            display_name: displayName,
            services: services
        )

        let _: User = try await api.request(
            path: "/auth/register",
            method: "POST",
            body: request
        )
    }

    func me(token: String) async throws -> User {
        let response: User = try await api.request(
            path: "/auth/me",
            token: token
        )
        return response
    }
}
