import SwiftUI

struct LanguageToggleButton: View {
    @EnvironmentObject private var languageSettings: LanguageSettings

    var body: some View {
        Button(languageSettings.currentLanguage.toggleLabel) {
            languageSettings.toggleLanguage()
        }
    }
}
