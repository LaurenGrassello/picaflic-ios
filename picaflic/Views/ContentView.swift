//
//  ContentView.swift
//  picaflic
//
//  Created by Lauren Odalen on 3/12/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "film")
                .font(.system(size: 60))

            Text("Pic-a-Flic")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Find your next movie")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button("Start Swiping") {
                print("Start Swiping tapped")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
