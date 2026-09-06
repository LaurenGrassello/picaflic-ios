import SwiftUI

struct ProviderIconStack: View {
    let providers: [(id: Int, name: String, asset: String?)]
    let maxShown: Int = 2

    var body: some View {
        HStack(spacing: -6) {
            ForEach(providers.prefix(maxShown), id: \.id) { provider in
                if let asset = provider.asset {
                    Image(asset)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 22, height: 22)
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                        .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color("BrandCharcoal"), lineWidth: 1.5))
                }
            }

            if providers.count > maxShown {
                Text("+\(providers.count - maxShown)")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 22, height: 22)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color("BrandCharcoal"), lineWidth: 1.5))
            }
        }
    }
}
