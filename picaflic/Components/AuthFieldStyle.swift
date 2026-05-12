import SwiftUI

struct AuthFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .frame(height: 58)
            .background(Color.white.opacity(0.18))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .shadow(color: .black.opacity(0.35), radius: 5, x: 0, y: 4)
    }
}

extension View {
    func authFieldStyle() -> some View {
        modifier(AuthFieldStyle())
    }
}
