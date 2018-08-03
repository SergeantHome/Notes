
import UIKit
import CoreData

class ListViewController: UIViewController {

    static let kEditNoteSegueIdentifier = "editNoteSegueIdentifier"
    let kNoteCellIdentifier = "NoteCellIdentifier"
    
    let viewModel: NoteListProtocol = NoteListViewModel(dataService: DataManager.shared)
    var activityIndicator: UIActivityIndicatorView?

    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        setCallbacks(viewModel: self.viewModel)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.title = LocalizedString("noteListControllerTitle")
        let preferredLanguageID = Locale.preferredLanguages.first ?? "en"
        self.navigationItem.leftBarButtonItem?.title = flag(langID: preferredLanguageID) //preferredLanguageID.uppercased()
        if case .updating = viewModel.listState, activityIndicator == nil {
            self.showModalSpinner()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == ListViewController.kEditNoteSegueIdentifier, let destinationVC = segue.destination as? EditNoteViewController {
            destinationVC.viewModel = self.viewModel
        }
    }
    
    // MARK: - User actions
    
    @IBAction func addNoteTapped(_ sender: UIBarButtonItem) {
        viewModel.startEdit(at: nil)
    }
    
    // MARK: - Helpers

    func setCallbacks(viewModel: NoteListProtocol) {
        viewModel.onStartEditing = { [weak self] indexPath in
            self?.performSegue(withIdentifier: ListViewController.kEditNoteSegueIdentifier, sender: indexPath)
        }
        viewModel.onDataUpdated = { [weak self] () in
            DispatchQueue.main.async {
                self?.tableView.reloadData()
            }
        }
        viewModel.onLoadingStatusChange = { [weak self] isBusy in
            DispatchQueue.main.async {
                if isBusy {
                    self?.showModalSpinner()
                } else {
                    self?.hideModalSpinner()
                }
            }
        }
        viewModel.onGotError = { error in
            showError(error?.localizedDescription ?? ("Empty Error Description"), in: self)
        }
    }
    
    func showModalSpinner() {
        
        UIApplication.shared.beginIgnoringInteractionEvents()
        
        var indicator = UIActivityIndicatorView()
        
        indicator = UIActivityIndicatorView(frame: self.view.frame)
        indicator.center = self.view.center
        indicator.backgroundColor = UIColor(white: 0.0, alpha: 0.5)
        indicator.activityIndicatorViewStyle = .whiteLarge
        indicator.hidesWhenStopped = true
        indicator.startAnimating()
        
        self.activityIndicator = indicator
        
        self.view.addSubview(indicator)
    }
    
    func hideModalSpinner() {
        self.activityIndicator?.stopAnimating()
        self.activityIndicator?.removeFromSuperview()
        
        UIApplication.shared.endIgnoringInteractionEvents()
    }
    
    func flag(langID: String) -> String {
        let countryCode = langID != "en" ? langID.uppercased() : "GB"
        let base: UInt32 = 127397
        return countryCode.unicodeScalars.compactMap { String.init(UnicodeScalar(base + $0.value)!) }.joined()
    }
}

extension ListViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfNotes
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: kNoteCellIdentifier, for: indexPath)
        let noteViewModel = viewModel.note(at: indexPath)
        cell.textLabel?.text = noteViewModel.noteText
        return cell
    }
}

extension ListViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        viewModel.startEdit(at: indexPath)
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let deleteAction = UITableViewRowAction(style: .destructive, title: LocalizedString("deleteButtonTitle")) { (action, indexPath) in
            self.viewModel.delele(at: indexPath)
        }
        
        return [deleteAction]
    }
}
