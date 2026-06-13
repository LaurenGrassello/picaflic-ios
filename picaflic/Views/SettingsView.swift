import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authStore: AuthStore
    private let api = APIClient.shared

    @State private var showDeleteConfirm = false
    @State private var isDeleting = false
    @State private var deleteError: String? = nil

    var body: some View {
        ZStack {
            Color("BrandCharcoal").ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {

                    Image("EyeballGraphic")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60)
                        .padding(.top, 24)

                    Text("Settings")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color("BrandSand"))
                        .padding(.bottom, 8)

                    // Update Password
                    NavigationLink {
                        ChangePasswordView()
                            .environmentObject(authStore)
                    } label: {
                        settingsButton("Update password")
                    }
                    .buttonStyle(.plain)

                    // Update Streaming Services
                    NavigationLink {
                        StreamingServicesSelectionView(
                            isOnboarding: false,
                            onFinished: {}
                        )
                        .environmentObject(authStore)
                    } label: {
                        settingsButton("Update Streaming Services")
                    }
                    .buttonStyle(.plain)

                    // Change Username
                    NavigationLink {
                        UpdateUsernameView()
                            .environmentObject(authStore)
                    } label: {
                        settingsButton("Change Username")
                    }
                    .buttonStyle(.plain)

                    // Delete Account
                    Button {
                        showDeleteConfirm = true
                    } label: {
                        settingsButton("Delete Your Account")
                    }
                    .buttonStyle(.plain)

                    // Log Out
                    Button {
                        authStore.clear()
                    } label: {
                        settingsButton("Log Out")
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }

            // Custom delete confirmation overlay
            if showDeleteConfirm {
                deleteConfirmationOverlay
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Buttons

    private func settingsButton(_ title: String) -> some View {
        Text(title)
            .font(.headline.weight(.bold))
            .foregroundStyle(Color("BrandCharcoal"))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(Color("BrandTeal").opacity(0.85))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 3)
    }

    // MARK: - Delete Confirmation Overlay

    private var deleteConfirmationOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    showDeleteConfirm = false
                }

            VStack(spacing: 24) {
                HStack {
                    Spacer()
                    Button {
                        showDeleteConfirm = false
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(Color("BrandRust"))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }

                Text("Are you sure you would like\nto delete your account?")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color("BrandGold"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)

                if let error = deleteError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(Color("BrandRust"))
                }

                Button {
                    Task { await deleteAccount() }
                } label: {
                    Group {
                        if isDeleting {
                            ProgressView().tint(Color("BrandCharcoal"))
                        } else {
                            Text("Yes")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(Color("BrandCharcoal"))
                        }
                    }
                    .frame(width: 120)
                    .padding(.vertical, 14)
                    .background(Color("BrandTeal").opacity(0.85))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .disabled(isDeleting)
                .padding(.bottom, 8)
            }
            .padding(24)
            .background(Color.white.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .padding(.horizontal, 40)
        }
    }

    // MARK: - Data

    private func deleteAccount() async {
        guard let token = authStore.accessToken else { return }
        isDeleting = true
        deleteError = nil

        do {
            struct Response: Decodable { let ok: Bool? }
            let _: Response = try await api.request(
                path: "/profile",
                method: "DELETE",
                token: token
            )
            authStore.clear()
        } catch {
            deleteError = "Couldn't delete account. Try again."
        }

        isDeleting = false
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(AuthStore())
    }
}
