import Foundation

enum AppLanguage: String, CaseIterable {
    case english = "en"
    case mandarin = "zh-Hans"

    var locale: Locale {
        Locale(identifier: rawValue)
    }

    var toggleLabel: String {
        switch self {
        case .english:
            return "EN"
        case .mandarin:
            return "中文"
        }
    }

    var next: AppLanguage {
        switch self {
        case .english:
            return .mandarin
        case .mandarin:
            return .english
        }
    }
}

@MainActor
final class LanguageSettings: ObservableObject {
    @Published var currentLanguage: AppLanguage = .english

    var locale: Locale {
        currentLanguage.locale
    }

    func toggleLanguage() {
        currentLanguage = currentLanguage.next
    }
}
