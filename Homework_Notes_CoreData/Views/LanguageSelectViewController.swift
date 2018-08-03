
import UIKit

class LanguageSelectViewController: UITableViewController {
    
    let kLanguageCellIdentifier = "LanguageCellIdentifier"

    var appLocales = [Locale]()
    var preferredLanguageIDs = Locale.preferredLanguages

    override func viewDidLoad() {
        super.viewDidLoad()

        let bundleLocaleIDs = Bundle.main.localizations.filter { $0 != "Base" }
        for localeId in bundleLocaleIDs {
            let installedLocale = Locale(identifier: localeId)
            appLocales.append(installedLocale)
        }
        self.title = LocalizedString("languagesControllerTitle")
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return appLocales.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: kLanguageCellIdentifier, for: indexPath)

        let locale = appLocales[indexPath.row]
        cell.textLabel?.text = locale.localizedString(forIdentifier: locale.identifier)
        cell.accessoryType = preferredLanguageIDs.contains(locale.identifier) ? .checkmark : .none

        return cell
    }

    // MARK: - Table view delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let locale = appLocales[indexPath.row]
        UserDefaults.standard.set([locale.identifier], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
        LocalizationSetLanguage(locale.identifier)
        tableView.deselectRow(at: indexPath, animated: true)
        self.navigationController?.popViewController(animated: true)
    }
}
