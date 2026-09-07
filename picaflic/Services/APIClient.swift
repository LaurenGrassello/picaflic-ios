import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case server(String)
    case decoding(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL."
        case .invalidResponse:
            return "Invalid server response."
        case .unauthorized:
            return "Unauthorized."
        case .server(let message):
            return message
        case .decoding:
            return "Failed to decode response."
        }
    }
}

struct AnyEncodable: Encodable {
    private let encodeClosure: (Encoder) throws -> Void

    init(_ wrapped: Encodable) {
        self.encodeClosure = wrapped.encode
    }

    func encode(to encoder: Encoder) throws {
        try encodeClosure(encoder)
    }
}

final class APIClient {
    static let shared = APIClient()

    // Update if your backend runs on a different host/port
    private let baseURL = "https://pic-a-flic-production.up.railway.app"

    // Wired up by AuthStore at launch so APIClient can silently refresh
    // sessions and know when to sign the user out, without owning AuthStore directly.
    var getRefreshToken: (() -> String?)?
    var onTokensRefreshed: ((_ accessToken: String, _ refreshToken: String) -> Void)?
    var onSessionExpired: (() -> Void)?

    private var refreshTask: Task<String?, Never>?

    private init() {}

    // MARK: - Public request (with automatic refresh-on-401)

    func request<T: Decodable>(
        path: String,
        method: String = "GET",
        token: String? = nil,
        body: Encodable? = nil
    ) async throws -> T {
        do {
            return try await performRequest(path: path, method: method, token: token, body: body)
        } catch APIError.unauthorized {
            // Never attempt to refresh using the refresh endpoint itself.
            guard path != "/auth/refresh" else {
                onSessionExpired?()
                throw APIError.unauthorized
            }

            if let newToken = await refreshAccessTokenIfNeeded() {
                // Retry the original request exactly once with the new token.
                return try await performRequest(path: path, method: method, token: newToken, body: body)
            } else {
                onSessionExpired?()
                throw APIError.unauthorized
            }
        }
    }

    // MARK: - Refresh coordination

    /// Ensures only one refresh happens at a time, even if multiple requests
    /// hit a 401 concurrently — they all await the same in-flight refresh.
    private func refreshAccessTokenIfNeeded() async -> String? {
        if let existing = refreshTask {
            return await existing.value
        }

        let task = Task<String?, Never> { [weak self] in
            guard let self else { return nil }
            guard let refreshToken = self.getRefreshToken?(), !refreshToken.isEmpty else {
                return nil
            }

            struct RefreshRequest: Encodable {
                let refresh_token: String
            }
            struct RefreshResponse: Decodable {
                let token: String
                let refresh_token: String
            }

            do {
                let response: RefreshResponse = try await self.performRequest(
                    path: "/auth/refresh",
                    method: "POST",
                    token: nil,
                    body: RefreshRequest(refresh_token: refreshToken)
                )
                self.onTokensRefreshed?(response.token, response.refresh_token)
                return response.token
            } catch {
                return nil
            }
        }

        refreshTask = task
        let result = await task.value
        refreshTask = nil
        return result
    }

    // MARK: - Raw request (no refresh handling — used internally)

    private func performRequest<T: Decodable>(
        path: String,
        method: String = "GET",
        token: String? = nil,
        body: Encodable? = nil
    ) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(path)") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(AnyEncodable(body))
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if http.statusCode == 401 {
            throw APIError.unauthorized
        }

        guard 200..<300 ~= http.statusCode else {
            if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let message = obj["error"] as? String {
                throw APIError.server(message)
            }
            throw APIError.invalidResponse
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw APIError.decoding(error)
        }
    }
}
