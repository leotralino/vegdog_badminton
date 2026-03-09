import SwiftUI

enum CuteTheme {
    static let mint = Color(red: 0.78, green: 0.93, blue: 0.78)
    static let leaf = Color(red: 0.33, green: 0.63, blue: 0.41)
    static let cream = Color(red: 0.98, green: 0.99, blue: 0.95)
    static let ink = Color(red: 0.17, green: 0.25, blue: 0.16)
    static let notionBlock = Color(red: 0.95, green: 0.97, blue: 0.95)
    static let notionBorder = Color(red: 0.84, green: 0.90, blue: 0.84)
    static let notionChip = Color(red: 0.88, green: 0.94, blue: 0.87)
}

struct DoodleCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(14)
            .background(CuteTheme.cream)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round, dash: [7, 4])
                    )
                    .foregroundStyle(CuteTheme.leaf.opacity(0.65))
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
    }
}

extension View {
    func doodleCard() -> some View {
        modifier(DoodleCard())
    }

    func notionCard() -> some View {
        padding(14)
            .background(CuteTheme.notionBlock)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(CuteTheme.notionBorder, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct MetaChip: View {
    let label: LocalizedStringKey
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(CuteTheme.notionChip)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
