import SwiftUI

struct VegDogLogoView: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color(red: 0.91, green: 0.98, blue: 0.88))
            Circle()
                .fill(Color(red: 0.55, green: 0.80, blue: 0.45))
                .frame(width: 76, height: 76)
            Ellipse()
                .fill(Color(red: 0.92, green: 0.78, blue: 0.60))
                .frame(width: 54, height: 42)
                .offset(y: 8)
            Circle()
                .fill(.black)
                .frame(width: 5, height: 5)
                .offset(x: -10, y: 4)
            Circle()
                .fill(.black)
                .frame(width: 5, height: 5)
                .offset(x: 10, y: 4)
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(red: 0.2, green: 0.45, blue: 0.2))
                .frame(width: 38, height: 4)
                .offset(y: -14)
            Capsule()
                .fill(Color(red: 0.96, green: 0.96, blue: 0.96))
                .frame(width: 22, height: 6)
                .rotationEffect(.degrees(-25))
                .offset(x: 32, y: -22)
            Capsule()
                .fill(Color(red: 0.86, green: 0.22, blue: 0.24))
                .frame(width: 3, height: 26)
                .rotationEffect(.degrees(-25))
                .offset(x: 37, y: -27)
        }
    }
}
