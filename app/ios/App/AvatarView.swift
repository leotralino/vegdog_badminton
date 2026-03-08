import SwiftUI

struct AvatarView: View {
    let avatarURL: String?
    var size: CGFloat = 32

    var body: some View {
        Group {
            if
                let avatarURL,
                let url = URL(string: avatarURL),
                !avatarURL.isEmpty
            {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    fallback
                }
            } else {
                fallback
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    private var fallback: some View {
        ZStack {
            Circle()
                .fill(Color(.systemGray5))
            Image(systemName: "person.fill")
                .font(.system(size: size * 0.46))
                .foregroundStyle(.secondary)
        }
    }
}
