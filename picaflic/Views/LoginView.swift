import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authStore: AuthStore

    private let authService = AuthService()

    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color("BrandCharcoal")
                    .ignoresSafeArea()

                VStack(spacing: 28) {
                    Spacer(minLength: 34)

                    AuthLogoView()

                    Text("Spend more time watching\nand less time scrolling.")
                        .font(.title3.weight(.medium))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 32)

                    VStack(spacing: 16) {
                        TextField("", text: $email, prompt: Text("Email").foregroundColor(.white.opacity(0.65)))
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.emailAddress)
                            .authFieldStyle()

                        SecureField("", text: $password, prompt: Text("Password").foregroundColor(.white.opacity(0.65)))
                            .authFieldStyle()

                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .foregroundStyle(Color("BrandRust"))
                                .font(.footnote)
                                .multilineTextAlignment(.center)
                        }

                        Button {
                            Task { await login() }
                        } label: {
                            Group {
                                if isLoading {
                                    ProgressView()
                                        .tint(.white)
                                        .frame(maxWidth: .infinity)
                                } else {
                                    Text("Log In")
                                        .fontWeight(.semibold)
                                        .frame(maxWidth: .infinity)
                                }
                            }
                            .padding()
                            .background(Color("BrandGold"))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .shadow(color: .black.opacity(0.35), radius: 5, x: 0, y: 4)
                        }
                        .disabled(isLoading)

                        NavigationLink {
                            RegisterView()
                                .environmentObject(authStore)
                        } label: {
                            Text("Create an Account")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(Color("BrandTeal"))
                                .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 3)
                        }
                        .padding(.top, 4)
                    }
                    .padding(.horizontal, 40)

                    Spacer()
                }
                .padding(.vertical, 18)
            }
        }
    }

    private func login() async {
        errorMessage = ""
        isLoading = true

        do {
            let auth = try await authService.login(email: email, password: password)
            authStore.saveAuth(auth)

            if let token = authStore.accessToken {
                let user = try await authService.me(token: token)
                authStore.currentUser = user
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthStore())
}
