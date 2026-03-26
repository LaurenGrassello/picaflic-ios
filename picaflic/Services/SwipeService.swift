//
//  SwipeService.swift
//  picaflic
//
//  Created by Lauren Odalen on 3/26/26.
//

import Foundation

struct SwipeRequest: Encodable {
    let movie_id: Int
    let liked: Bool
}

struct SwipeResponse: Decodable {
    let ok: Bool
}

final class SwipeService {
    private let api = APIClient.shared

    func sendSwipe(token: String, movieId: Int, liked: Bool) async throws {
        let body = SwipeRequest(movie_id: movieId, liked: liked)

        let _: SwipeResponse = try await api.request(
            path: "/social/swipe",
            method: "POST",
            token: token,
            body: body
        )
    }
}
