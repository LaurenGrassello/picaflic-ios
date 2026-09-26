import SwiftUI

struct SharedWatchlistDetailView: View {
    let share: PersonalWatchlistShare
    @EnvironmentObject var authStore: AuthStore

    var body: some View {
        ZStack {
            Color("BrandCharcoal").ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Image("EyeballGraphic")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100)

                VStack(spacing: 6) {
                    Text(share.watchlist_name)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color("BrandSand"))
                    Text("Shared by \(share.owner_display_name)")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                }

                VStack(spacing: 14) {
                    NavigationLink {
                        PersonalShareSwipeView(
                            shareId: share.share_id,
                            watchlistName: share.watchlist_name,
                            ownerName: share.owner_display_name
                        )
                        .environmentObject(authStore)
                    } label: {
                        Text("Start Swiping")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color("BrandGold"))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    NavigationLink {
                        PersonalShareMatchesView(
                            shareId: share.share_id,
                            watchlistName: share.watchlist_name
                        )
                        .environmentObject(authStore)
                    } label: {
                        Text("View Matches\(share.match_count > 0 ? " (\(share.match_count))" : "")")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(Color("BrandGold"))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color("BrandGold").opacity(0.12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color("BrandGold").opacity(0.5), lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding(.horizontal, 32)

                Spacer()
                Spacer()
            }
        }
        .navigationTitle(share.watchlist_name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SharedWatchlistDetailView(
            share: PersonalWatchlistShare(
                share_id: 1,
                watchlist_id: 1,
                watchlist_name: "Date Night",
                owner_user_id: 2,
                owner_display_name: "Jess",
                status: "accepted",
                match_count: 0
            )
        )
        .environmentObject(AuthStore())
    }
}
