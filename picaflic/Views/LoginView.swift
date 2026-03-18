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
            VStack(spacing: 20) {
                Text("Pic-a-Flic")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                TextField("Email", text: $email)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.emailAddress)
                    .textFieldStyle(.roundedBorder)

                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.footnote)
                }

                Button {
                    Task {
                        await login()
                    }
                } label: {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Login")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoading)

                NavigationLink("Create Account") {
                    RegisterView()
                }
            }
            .padding()
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
