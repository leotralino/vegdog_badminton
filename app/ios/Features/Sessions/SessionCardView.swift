import SwiftUI

struct SessionCardView: View {
    let session: Session

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(session.title)
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                MetaChip(label: "sessions.create.starts_at", value: DateDisplay.session(session.startsAt))
                MetaChip(label: "sessions.create.location_placeholder", value: session.location)
                MetaChip(label: "sessions.initiator", value: session.initiatorUser.nickname)
                MetaChip(label: "sessions.max_people_label", value: "\(session.maxParticipants)")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .notionCard()
    }
}
