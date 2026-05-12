import SwiftUI

struct StreamingServicesSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authStore: AuthStore

    let isOnboarding: Bool
    let onFinished: () -> Void

    private let service = StreamingServicesService()

    // Curated ordered list with asset names
    private let serviceOptions: [(id: Int, name: String, asset: String)] = [
        (8,    "Netflix",     "ServiceNetflix"),
        (1899, "Max",         "ServiceMax"),
        (15,   "Hulu",        "ServiceHulu"),
        (386,  "Peacock",     "ServicePeacock"),
        (337,  "Disney+",     "ServiceDisneyPlus"),
        (73,   "Tubi",        "ServiceTubi"),
        (350,  "Apple TV+",   "ServiceAppleTVPlus"),
        (99,   "Shudder",     "ServiceShudder"),
        (9,    "Prime Video", "ServicePrimeVideo"),
    ]

    @State private var selectedIds: Set<Int> = []
    @State private var isLoading = false
    @State private var isSaving = false
    @State private var errorMessage = ""
    @State private var showSkipAlert = false

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color("BrandCharcoal").ignoresSafeArea()

                VStack(spacing: 16) {
                    headerView

                    if isLoading {
                        Spacer()
                        ProgressView("Loading services...")
                            .tint(Color("BrandSand"))
                            .foregroundStyle(Color("BrandSand"))
                        Spacer()
                    } else {
                        ScrollView {
                            VStack(spacing: 24) {
                                Text("Select the services you subscribe to and we will compile a selection of movies available on them.")
                                    .font(.subheadline)
                                    .foregroundStyle(Color("BrandSand").opacity(0.9))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 8)

                                LazyVGrid(columns: columns, spacing: 16) {
                                    ForEach(serviceOptions, id: \.id) { option in
                                        serviceIconButton(option)
                                    }
                                }

                                if !errorMessage.isEmpty {
                                    Text(errorMessage)
                                        .foregroundStyle(Color("BrandRust"))
                                        .font(.caption)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                        }

                        bottomActions
                    }
                }
            }
            .navigationTitle(isOnboarding ? "Streaming Services" : "Update Services")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !isOnboarding {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Close") { dismiss() }
                            .foregroundStyle(Color("BrandSand"))
                    }
                }
            }
            .task { await loadData() }
            .alert("Skip for now?", isPresented: $showSkipAlert) {
                Button("Got it!") { finishFlow() }
                Button("Go Back", role: .cancel) { }
            } message: {
                Text("No worries! You can update your streaming services to personalize your experience later from your profile.")
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(spacing: 12) {
            Image("EyeballGraphic")
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)

            Text(isOnboarding ? "Pick Your Services" : "Update Your Services")
                .font(.title2.weight(.bold))
                .foregroundStyle(Color("BrandSand"))
        }
        .padding(.top, 12)
    }

    // MARK: - Icon Button

    private func serviceIconButton(_ option: (id: Int, name: String, asset: String)) -> some View {
        let isSelected = selectedIds.contains(option.id)

        return Button {
            toggle(option.id)
        } label: {
            Image(option.asset)
                .resizable()
                .scaledToFill()                          // fills the frame uniformly
                .frame(width: 90, height: 90)            // enforces identical size
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            isSelected ? Color("BrandRust") : Color.clear,
                            lineWidth: 3
                        )
                )
                .shadow(
                    color: isSelected ? Color("BrandRust").opacity(0.55) : .clear,
                    radius: 8
                )
                .animation(.easeInOut(duration: 0.15), value: isSelected)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Bottom Actions

    private var bottomActions: some View {
        VStack(spacing: 12) {
            Button {
                Task { await saveSelections() }
            } label: {
                Group {
                    if isSaving {
                        ProgressView().tint(.white)
                    } else {
                        Text("Save Services")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color("BrandGold"))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .disabled(isSaving)

            if isOnboarding {
                Button {
                    showSkipAlert = true
                } label: {
                    Text("Skip this for now")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color("BrandSand"))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }

    // MARK: - Logic

    private func toggle(_ id: Int) {
        if selectedIds.contains(id) {
            selectedIds.remove(id)
        } else {
            selectedIds.insert(id)
        }
    }

    private func loadData() async {
        guard let token = authStore.accessToken else {
            errorMessage = "Missing auth token."
            return
        }

        isLoading = true
        errorMessage = ""

        do {
            let mineResults = try await service.fetchMyServices(token: token)
            selectedIds = Set(mineResults)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func saveSelections() async {
        guard let token = authStore.accessToken else {
            errorMessage = "Missing auth token."
            return
        }

        isSaving = true
        errorMessage = ""

        do {
            let saved = try await service.saveMyServices(
                token: token,
                providerIds: Array(selectedIds).sorted()
            )
            selectedIds = Set(saved)
            finishFlow()
        } catch {
            errorMessage = error.localizedDescription
        }

        isSaving = false
    }

    private func finishFlow() {
        if isOnboarding {
            UserDefaults.standard.set(false, forKey: "show_username_onboarding")
            UserDefaults.standard.set(false, forKey: "show_welcome_onboarding")
            UserDefaults.standard.set(false, forKey: "show_streaming_onboarding")
            onFinished()
        } else {
            dismiss()
        }
    }
}

#Preview {
    StreamingServicesSelectionView(isOnboarding: true, onFinished: {})
        .environmentObject(AuthStore())
}
