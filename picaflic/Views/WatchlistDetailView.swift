import SwiftUI

struct WatchlistDetailView: View {
    let watchlistId: Int
    let watchlistName: String

    var body: some View {
        ZStack {
            Color("BrandCharcoal")
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Image("EyeballGraphic")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 70)

                Text(watchlistName)
                    .font(.title.weight(.bold))
                    .foregroundStyle(Color("BrandSand"))
                    .multilineTextAlignment(.center)

                Text("Choose what you want to do in this watchlist.")
                    .foregroundStyle(Color("BrandSand").opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                NavigationLink {
                    SwipeView()
                } label: {
                    Text("Start Swiping")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color("BrandGold"))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                NavigationLink {
                    WatchlistMatchesView(
                        watchlistId: watchlistId,
                        watchlistName: watchlistName
                    )
                } label: {
                    Text("View Matches")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color("BrandTeal"))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(24)
        }
        .navigationTitle("Watchlist")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        WatchlistDetailView(watchlistId: 1, watchlistName: "Friday Night Picks")
    }
}
