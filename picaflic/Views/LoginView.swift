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

                VStack(spacing: 24) {
                    Spacer(minLength: 24)

                    Image("EyeballGraphic")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 180)

                    VStack(spacing: 8) {
                        Text("Pic-A-Flic")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundStyle(Color("BrandSand"))

                        Text("Spend less time scrolling and more time watching.")
                            .font(.subheadline)
                            .foregroundStyle(Color("BrandSand").opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }

                    VStack(spacing: 14) {
                        TextField("", text: $email, prompt: Text("Email").foregroundColor(Color("BrandSand").opacity(0.7)))
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.emailAddress)
                            .padding()
                            .background(Color.white.opacity(0.08))
                            .foregroundColor(.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color("BrandSand").opacity(0.25), lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))

                        SecureField("", text: $password, prompt: Text("Password").foregroundColor(Color("BrandSand").opacity(0.7)))
                            .padding()
                            .background(Color.white.opacity(0.08))
                            .foregroundColor(.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color("BrandSand").opacity(0.25), lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal, 24)

                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundStyle(Color("BrandRust"))
                            .font(.footnote)
                            .padding(.horizontal, 24)
                    }

                    Button(action: {
                        Task {
                            await login()
                        }
                    }) {
                        Group {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                                    .frame(maxWidth: .infinity)
                            } else {
                                Text("Login")
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .padding()
                        .background(Color("BrandGold"))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal, 24)
                    .disabled(isLoading)

                    NavigationLink(destination: RegisterView()) {
                        Text("Create Account")
                            .fontWeight(.medium)
                            .foregroundStyle(Color("BrandTeal"))
                    }

                    Spacer()
                }
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
