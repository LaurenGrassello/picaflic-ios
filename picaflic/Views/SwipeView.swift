//
//  SwipeView.swift
//  picaflic
//
//  Created by Lauren Odalen on 3/26/26.
//

import SwiftUI

struct SwipeView: View {
    @EnvironmentObject var authStore: AuthStore

    private let feedService = FeedService()
    private let swipeService = SwipeService()

    @State private var items: [FeedItem] = []
    @State private var currentIndex = 0
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var dragOffset: CGSize = .zero

    var body: some View {
        NavigationStack {
            ZStack {
                Color("BrandCharcoal")
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    headerView

                    Spacer()

                    if isLoading {
                        ProgressView("Loading picks...")
                            .tint(Color("BrandSand"))
                            .foregroundStyle(Color("BrandSand"))
                    } else if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundStyle(Color("BrandRust"))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    } else if let item = currentItem {
                        swipeCard(for: item)
                    } else {
                        emptyStateView
                    }

                    Spacer()

                    controlsView
                }
                .padding()
            }
            .navigationBarHidden(true)
            .task {
                if items.isEmpty {
                    await loadFeed()
                }
            }
        }
    }
    
    private var fallbackView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.08))

            Image(systemName: "film")
                .font(.system(size: 48))
                .foregroundStyle(Color("BrandSand"))
        }
    }

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Pic-A-Flic")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Color("BrandSand"))

                Text("We help the indecisive be decisive.")
                    .font(.footnote)
                    .foregroundStyle(Color("BrandSand").opacity(0.8))
            }

            Spacer()

            Button("Logout") {
                authStore.clear()
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color("BrandTeal"))
        }
    }

    @ViewBuilder
    private func swipeCard(for item: FeedItem) -> some View {
        VStack(spacing: 0) {
            AsyncImage(url: item.posterURL, transaction: Transaction(animation: .easeIn)) { phase in
                switch phase {
                case .empty:
                    ZStack {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.white.opacity(0.08))
                        ProgressView().tint(Color("BrandSand"))
                    }

                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()

                case .failure:
                    fallbackView

                @unknown default:
                    fallbackView
                }
            }
            .frame(width: 300, height: 420)
            .clipShape(RoundedRectangle(cornerRadius: 24))

            VStack(alignment: .leading, spacing: 10) {
                Text(item.title)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color("BrandSand"))

                HStack(spacing: 12) {
                    Text(item.isTV ? "TV" : "Movie")
                    if let release = item.release_date, !release.isEmpty {
                        Text(release)
                    }
                }
                .font(.subheadline)
                .foregroundStyle(Color("BrandSand").opacity(0.85))

                if let localId = item.localId {
                    Text("Local ID: \(localId)")
                        .font(.caption)
                        .foregroundStyle(Color("BrandTeal"))
                } else {
                    Text("TMDB only item")
                        .font(.caption)
                        .foregroundStyle(Color("BrandRust"))
                }
            }
            .frame(width: 300, alignment: .leading)
            .padding(.top, 16)
            .padding(.bottom, 10)
        }
        .offset(x: dragOffset.width, y: dragOffset.height * 0.15)
        .rotationEffect(.degrees(Double(dragOffset.width / 20)))
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = value.translation
                }
                .onEnded { value in
                    handleSwipeGesture(value)
                }
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: dragOffset)
    }

    private var controlsView: some View {
        HStack(spacing: 18) {
            controlButton(
                systemName: "backward.end.fill",
                color: Color("BrandTeal")
            ) {
                moveBackward()
            }

            controlButton(
                systemName: "xmark",
                color: Color("BrandRust")
            ) {
                Task {
                    await submitCurrentSwipe(liked: false)
                }
            }

            controlButton(
                systemName: "heart.fill",
                color: Color("BrandGold")
            ) {
                Task {
                    await submitCurrentSwipe(liked: true)
                }
            }

            controlButton(
                systemName: "forward.end.fill",
                color: Color("BrandTeal")
            ) {
                moveForwardWithoutVote()
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image("EyeballGraphic")
                .resizable()
                .scaledToFit()
                .frame(width: 140)

            Text("No more picks right now")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color("BrandSand"))

            Button("Reload Feed") {
                Task {
                    await loadFeed()
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color("BrandGold"))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
    
    private func preloadNextImage() {
        let nextIndex = currentIndex + 1
        guard items.indices.contains(nextIndex) else { return }
        guard let url = items[nextIndex].posterURL else { return }

        URLSession.shared.dataTask(with: url).resume()
    }

    private func controlButton(systemName: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 58, height: 58)
                .background(color)
                .clipShape(Circle())
        }
    }

    private var currentItem: FeedItem? {
        guard items.indices.contains(currentIndex) else { return nil }
        return items[currentIndex]
    }

    private func loadFeed() async {
        errorMessage = ""
        isLoading = true
        currentIndex = 0

        guard let token = authStore.accessToken else {
            errorMessage = "Missing auth token."
            isLoading = false
            return
        }

        do {
            let results = try await feedService.fetchForYou(
                token: token,
                query: nil
            )
            items = results
            preloadNextImage()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func handleSwipeGesture(_ value: DragGesture.Value) {
        let horizontalAmount = value.translation.width

        if horizontalAmount > 120 {
            Task {
                await submitCurrentSwipe(liked: true)
            }
        } else if horizontalAmount < -120 {
            Task {
                await submitCurrentSwipe(liked: false)
            }
        } else {
            dragOffset = .zero
        }
    }

    private func submitCurrentSwipe(liked: Bool) async {
        guard let item = currentItem else { return }

        defer {
            dragOffset = .zero
            moveForward()
        }

        guard let token = authStore.accessToken else {
            errorMessage = "Missing auth token."
            return
        }

        guard let localId = item.localId else {
            return
        }

        do {
            try await swipeService.sendSwipe(
                token: token,
                movieId: localId,
                liked: liked
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func moveForward() {
        if currentIndex < items.count - 1 {
            currentIndex += 1
            preloadNextImage()
        } else {
            currentIndex = items.count
        }
    }

    private func moveForwardWithoutVote() {
        dragOffset = .zero
        moveForward()
    }

    private func moveBackward() {
        guard !items.isEmpty else { return }
        if currentIndex > 0 {
            currentIndex -= 1
        }
        dragOffset = .zero
    }
}

#Preview {
    SwipeView()
        .environmentObject(AuthStore())
}
