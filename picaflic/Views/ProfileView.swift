import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authStore: AuthStore
    @EnvironmentObject var inboxStore: InboxStore
    @State private var displayName: String = ""

    var body: some View {
        ZStack {
            Color("BrandCharcoal").ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    
                    // Header — rental card
                    VStack(spacing: 8) {
                        Image("EyeballGraphic")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .padding(.top, 16)
                        
                        ZStack(alignment: .bottomTrailing) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.white.opacity(0.055))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Color("BrandTeal").opacity(0.65), lineWidth: 1.2)
                                    )
                                    .shadow(color: Color("BrandTeal").opacity(0.4), radius: 12)
                                
                                VStack(spacing: 0) {
                                    Image("TealLetterLogo")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 180)
                                        .padding(.top, 16)
                                        .padding(.bottom, 12)
                                    
                                    VStack(spacing: 0) {
                                        HStack {
                                            Text(displayName.isEmpty ? "Welcome" : "Welcome, \(displayName)")
                                                .font(.title3)
                                                .foregroundStyle(.white.opacity(0.82))
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.7)
                                            Spacer()
                                            Color.clear.frame(width: 56)
                                        }
                                        .padding(.horizontal, 20)
                                        .frame(height: 48)
                                        .background(Color("BrandSand").opacity(0.85))
                                        
                                        Rectangle()
                                            .fill(Color("BrandGold"))
                                            .frame(height: 20)
                                    }
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                    .padding(.horizontal, 16)
                                    .padding(.bottom, 20)
                                }
                            }
                            
                            Image("YellowFriend")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 70, height: 70)
                                .offset(x: -10, y: -10)
                        }
                        .frame(height: 180)
                        .padding(.horizontal, 24)
                        
                        // Menu grid
                        VStack(spacing: 14) {
                            HStack(spacing: 14) {
                                // Inbox — mailbox with envelope overlay if pending
                                NavigationLink {
                                    InboxView()
                                        .environmentObject(authStore)
                                        .environmentObject(inboxStore)
                                } label: {
                                    menuButton(
                                        title: "Inbox",
                                        badge: inboxStore.pendingCount > 0 ? inboxStore.pendingCount : nil
                                    ) {
                                        ZStack(alignment: .bottomTrailing) {
                                            Image(inboxStore.pendingCount > 0 ? "Inbox_Envelope" : "Inbox")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 32, height: 32)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                                
                                // Search
                                NavigationLink {
                                    HomeView()
                                        .environmentObject(authStore)
                                } label: {
                                    menuButton(title: "Search") {
                                        Image("Mystery_or_Search")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 32, height: 32)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                            
                            HStack(spacing: 14) {
                                // Watchlists
                                NavigationLink {
                                    WatchlistsView()
                                        .environmentObject(authStore)
                                } label: {
                                    menuButton(title: "Watchlists") {
                                        Image("EyeballGraphic")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 32, height: 32)
                                    }
                                }
                                .buttonStyle(.plain)
                                
                                // Friends
                                NavigationLink {
                                    FriendsView()
                                        .environmentObject(authStore)
                                } label: {
                                    menuButton(title: "Friends") {
                                        Image("Friends_Avatars")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 32, height: 32)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                            
                            HStack(spacing: 14) {
                                // About
                                NavigationLink {
                                    AboutView()
                                } label: {
                                    menuButton(title: "About") {
                                        Image("LogoEyeV2")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 32, height: 32)
                                    }
                                }
                                .buttonStyle(.plain)
                                
                                // Settings
                                NavigationLink {
                                    SettingsView()
                                        .environmentObject(authStore)
                                } label: {
                                    menuButton(title: "Settings") {
                                        Image("Settings")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 32, height: 32)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
                    }
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await inboxStore.refresh(token: authStore.accessToken)
            await loadDisplayName()
        }
    }

    private func loadDisplayName() async {
        guard let token = authStore.accessToken else { return }
        do {
            struct MeResponse: Decodable {
                let display_name: String
            }
            let response: MeResponse = try await APIClient.shared.request(
                path: "/auth/me",
                token: token
            )
            displayName = response.display_name
        } catch {
            print("LOAD USER ERROR:", error)
        }
    }
    
    // MARK: - Menu Button

    private func menuButton<Icon: View>(
        title: String,
        badge: Int? = nil,
        @ViewBuilder icon: () -> Icon
    ) -> some View {
        HStack(spacing: 12) {
            ZStack(alignment: .topTrailing) {
                icon()

                if let badge, badge > 0 {
                    Text("\(badge)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(3)
                        .background(Color("BrandRust"))
                        .clipShape(Circle())
                        .offset(x: 6, y: -6)
                }
            }

            Text(title)
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color("BrandTeal").opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    NavigationStack {
        ProfileView()
            .environmentObject(AuthStore())
            .environmentObject(InboxStore())
    }
}
