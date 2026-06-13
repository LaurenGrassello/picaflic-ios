import SwiftUI

struct AboutView: View {
    var body: some View {
        ZStack {
            Color("BrandCharcoal").ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Image("EyeballGraphic")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80)
                        .padding(.top, 24)

                    Image("TealLetterLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200)

                    VStack(spacing: 16) {
                        aboutBlock(
                            title: "About Us",
                            body: "We had a problem, a problem I think a lot of us have struggled with. What to watch! Finding ourselves scrolling endlessly, wasting time to watch the same comfort show or run out of time completely. Looking at all the available options in each app can be daunting. In ode to the Video Rental Shop, we list all the available movies from your subscriptions together. Helping you feel the nostalgia of renting a movie on a Friday night. No longer logging in and out of all your apps and scrolling endlessly. Movie parties are fun! We encourage you to use this app to spend time with friends and loved ones watching movies and having discussions. Create watchlists and spend time enjoying the art of film."
                        )

                        aboutBlock(
                            title: "Solo Browse",
                            body: "Search and filter movies from your streaming services. Like, bookmark, and build your personal watchlists."
                        )

                        aboutBlock(
                            title: "Watch with Friends",
                            body: "Create a shared watchlist with friends and swipe together. When everyone picks the same movie — it's a match!"
                        )

                        aboutBlock(
                            title: "Version",
                            body: "Pic-a-Flic v1.0 — Built with ❤️"
                        )
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func aboutBlock(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline.weight(.bold))
                .foregroundStyle(Color("BrandTeal"))
            Text(body)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

#Preview {
    NavigationStack {
        AboutView()
    }
}
