import Foundation
import Combine

@MainActor
final class InboxStore: ObservableObject {
    @Published var pendingCount: Int = 0

    private let service = InboxService()

    func refresh(token: String?) async {
        guard let token, !token.isEmpty else {
            pendingCount = 0
            return
        }

        do {
            let counts = try await service.fetchCounts(token: token)
            pendingCount = counts.total
        } catch {
            print("INBOX COUNT ERROR:", error)
        }
    }

    func clear() {
        pendingCount = 0
    }
}
