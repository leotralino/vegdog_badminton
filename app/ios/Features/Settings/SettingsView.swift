import SwiftUI

struct SettingsView: View {
    let currentUser: User?
    let onSignOut: () -> Void
    @AppStorage("profile.nickname") private var nickname: String = ""
    @AppStorage("profile.avatar_url") private var avatarURL: String = ""
    @AppStorage("profile.payment") private var paymentInfo: String = ""
    @AppStorage("profile.gender") private var gender: String = ""
    @AppStorage("profile.level") private var level: String = ""

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
                    Picker("settings.gender", selection: $gender) {
                        Text("settings.gender_unspecified").tag("")
                        Text("settings.gender_male").tag("male")
                        Text("settings.gender_female").tag("female")
                        Text("settings.gender_other").tag("other")
                    }
                    TextField("settings.level", text: $level)
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
            .scrollContentBackground(.hidden)
            .background(
                LinearGradient(
                    colors: [CuteTheme.mint.opacity(0.35), CuteTheme.cream],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
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
