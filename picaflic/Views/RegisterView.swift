import SwiftUI

struct RegisterView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authStore: AuthStore

    private let authService = AuthService()

    @State private var email = ""
    @State private var password = ""
    @State private var username = ""
    @State private var errorMessage = ""
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color("BrandCharcoal")
                    .ignoresSafeArea()

                VStack(spacing: 28) {
                    Spacer(minLength: 44)

                    VStack(spacing: 14) {
                        Image("EyeballGraphic")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 64)
                            .shadow(color: Color("BrandGold").opacity(0.35), radius: 12, x: 0, y: 6)

                        Text("Create Your Account!")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(Color("BrandTeal"))

                        Text("So you can find what to watch \nbefore your pizza gets cold.")
                            .font(.subheadline)
                            .foregroundStyle(Color("BrandSand").opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }

                    VStack(spacing: 18) {
                        TextField("", text: $username, prompt: Text("Username").foregroundColor(Color("BrandSand").opacity(0.7)))
                            .authFieldStyle()

                        TextField("", text: $email, prompt: Text("Email").foregroundColor(Color("BrandSand").opacity(0.7)))
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.emailAddress)
                            .authFieldStyle()

                        SecureField("", text: $password, prompt: Text("Password").foregroundColor(Color("BrandSand").opacity(0.7)))
                            .authFieldStyle()
                    }
                    .padding(.horizontal, 36)
                    .padding(.top, 18)

                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundStyle(Color("BrandRust"))
                            .font(.footnote)
                            .padding(.horizontal, 24)
                    }

                    Button {
                        Task { await register() }
                    } label: {
                        Group {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                                    .frame(maxWidth: .infinity)
                            } else {
                                Text("Register")
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .padding()
                        .background(Color("BrandGold"))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal, 36)
                    .padding(.top, 8)
                    .disabled(isLoading)

                    Button("Back to Login") {
                        dismiss()
                    }
                    .fontWeight(.medium)
                    .foregroundStyle(Color("BrandTeal"))

                    Spacer(minLength: 36)
                }
            }
            
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(" ")
                }
            }
        }
    }

    private func register() async {
        errorMessage = ""
        isLoading = true

        do {
            try await authService.register(
                email: email,
                password: password,
                displayName: username,
                services: []
            )

            let auth = try await authService.login(email: email, password: password)
            authStore.save(auth)

            UserDefaults.standard.set(username, forKey: "onboarding_username")
            UserDefaults.standard.set(false, forKey: "show_username_onboarding")
            UserDefaults.standard.set(true, forKey: "show_welcome_onboarding")
            UserDefaults.standard.set(false, forKey: "show_streaming_onboarding")
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

#Preview {
    NavigationStack {
        RegisterView()
            .environmentObject(AuthStore())
    }
}
