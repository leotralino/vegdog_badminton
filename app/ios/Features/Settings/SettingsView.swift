import SwiftUI

struct SettingsView: View {
    let currentUser: User?
    let onSignOut: () -> Void
    @AppStorage("profile.nickname") private var nickname: String = ""
    @AppStorage("profile.avatar_url") private var avatarURL: String = ""
    @AppStorage("profile.payment") private var paymentInfo: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("settings.profile") {
                    HStack {
                        Spacer()
                        AvatarView(avatarURL: avatarURL, size: 72)
                        Spacer()
                    }
                    TextField("settings.avatar", text: $avatarURL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                    TextField("settings.nickname", text: $nickname)
                }

                Section("settings.payment") {
                    TextField("settings.payment_info", text: $paymentInfo)
                }

                Section("settings.account") {
                    Text(currentUser?.id ?? "-")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Button("common.sign_out", role: .destructive, action: onSignOut)
                }
            }
            .navigationTitle("settings.title")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    LanguageToggleButton()
                }
            }
            .onAppear {
                if nickname.isEmpty {
                    nickname = currentUser?.nickname ?? ""
                }
                if avatarURL.isEmpty {
                    avatarURL = currentUser?.avatarURL ?? ""
                }
            }
        }
    }
}
