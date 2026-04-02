import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authStore: AuthStore

    var body: some View {
        NavigationStack {
            ZStack {
                Color("BrandCharcoal")
                    .ignoresSafeArea()

                VStack(spacing: 18) {
                    Image("EyeballGraphic")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80)

                    Text("Profile")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(Color("BrandSand"))

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
                }
                .padding()
            }
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthStore())
}
