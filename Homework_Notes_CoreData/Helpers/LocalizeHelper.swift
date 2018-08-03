
import Foundation

func LocalizedString(_ key: String) -> String {
    return LocalizeHelper.shared.localizedString(for: key)
}

func LocalizationSetLanguage(_ lang: String) {
    return LocalizeHelper.shared.set(language: lang)
}

class LocalizeHelper {
    
    static let shared = LocalizeHelper()
    
    var resourceBundle: Bundle
    
    private init () {
        self.resourceBundle = Bundle.main
    }
    
    func localizedString(for key: String) -> String {
        return self.resourceBundle.localizedString(forKey: key, value: key, table: nil)
    }
    
    func set(language lang: String) {
        guard let path = Bundle.main.path(forResource: lang, ofType: "lproj"), let newBundle = Bundle(path: path) else { return }
        
        self.resourceBundle = newBundle
    }
}
