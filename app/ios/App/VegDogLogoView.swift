import SwiftUI

struct VegDogLogoView: View {
    var body: some View {
        Image("vegdog_logo")
            .resizable()
            .scaledToFit()
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
