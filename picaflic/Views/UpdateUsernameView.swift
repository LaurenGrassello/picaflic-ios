import SwiftUI

struct UpdateUsernameView: View {
    @EnvironmentObject var authStore: AuthStore
    @Environment(\.dismiss) private var dismiss

    private let api = APIClient.shared

    @State private var newUsername = ""
    @State private var isSaving = false
    @State private var errorMessage: String? = nil
    @State private var successMessage: String? = nil

    var body: some View {
        ZStack {
            Color("BrandCharcoal").ignoresSafeArea()

            VStack(spacing: 24) {
                Image("EyeballGraphic")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60)
                    .padding(.top, 24)

                Text("Change Username")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color("BrandSand"))

                VStack(spacing: 12) {
                    TextField("New username", text: $newUsername)
                        .foregroundStyle(.white)
                        .padding()
                        .background(Color.white.opacity(0.60))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(Color("BrandRust"))
                    }

                    if let success = successMessage {
                        Text(success)
                            .font(.caption)
                            .foregroundStyle(Color("BrandTeal"))
                    }
                }
                .padding(.horizontal, 24)

                Button {
                    Task { await save() }
                } label: {
                    Group {
                        if isSaving {
                            ProgressView().tint(.white)
                        } else {
                            Text("Save Username")
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("BrandGold"))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(newUsername.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                .padding(.horizontal, 24)
                .buttonStyle(.plain)

                Spacer()
            }
        }
        .navigationTitle("Username")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func save() async {
        guard let token = authStore.accessToken else { return }
        let trimmed = newUsername.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        isSaving = true
        errorMessage = nil
        successMessage = nil

        do {
            struct Body: Encodable { let display_name: String }
            struct Response: Decodable { let display_name: String? }
            let _: Response = try await api.request(
                path: "/profile/username",
                method: "POST",
                token: token,
                body: Body(display_name: trimmed)
            )
            successMessage = "Username updated!"
            newUsername = ""
        } catch {
            errorMessage = "Couldn't update username."
        }

        isSaving = false
    }
}

#Preview {
    NavigationStack {
        UpdateUsernameView()
            .environmentObject(AuthStore())
    }
}
