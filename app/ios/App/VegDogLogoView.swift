import SwiftUI
import UIKit

struct VegDogLogoView: View {
    private var logoImage: UIImage? {
        if let byName = UIImage(named: "vegdog_logo") {
            return byName
        }
        guard let path = Bundle.main.path(forResource: "vegdog_logo", ofType: "png") else {
            return nil
        }
        return UIImage(contentsOfFile: path)
    }

    var body: some View {
        Group {
            if let logoImage {
                Image(uiImage: logoImage)
                    .resizable()
                    .scaledToFit()
            } else {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(.systemGray5))
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 28))
                            .foregroundStyle(.secondary)
                    )
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
