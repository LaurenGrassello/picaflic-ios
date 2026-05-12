import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authStore: AuthStore
    @EnvironmentObject var inboxStore: InboxStore

    @State private var showStreamingServices = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color("BrandCharcoal")
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    Image("EyeballGraphic")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80)

                    Text("Profile")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(Color("BrandSand"))

                    Button {
                        showStreamingServices = true
                    } label: {
                        HStack {
                            Text("Update Streaming Services")
                                .font(.headline)
                                .foregroundStyle(.white)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundStyle(.gray)
                        }
                        .padding()
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 24)

                    NavigationLink {
                        InboxView()
                    } label: {
                        HStack {
                            Text("Inbox")
                                .font(.headline)
                                .foregroundStyle(.white)

                            Spacer()

                            if inboxStore.pendingCount > 0 {
                                Text("\(inboxStore.pendingCount)")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color("BrandRust"))
                                    .clipShape(Capsule())
                            }

                            Image(systemName: "chevron.right")
                                .foregroundStyle(.gray)
                        }
                        .padding()
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 24)

                    Text("Update streaming services and account settings here.")
                        .foregroundStyle(Color("BrandSand").opacity(0.85))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    Button("Logout") {
                        authStore.clear()
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color("BrandRust"))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 24)

                    Spacer()
                }
                .padding()
            }
            .task {
                await inboxStore.refresh(token: authStore.accessToken)
            }
            .sheet(isPresented: $showStreamingServices) {
                StreamingServicesSelectionView(
                    isOnboarding: false,
                    onFinished: { }
                )
                .environmentObject(authStore)
            }
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthStore())
        .environmentObject(InboxStore())
}
