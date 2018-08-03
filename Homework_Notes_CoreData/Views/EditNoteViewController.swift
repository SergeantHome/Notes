
import UIKit

class EditNoteViewController: UIViewController {
    
    @IBOutlet weak var textView: UITextView!
    
    var viewModel: NoteListProtocol?
    var noteViewModel: NoteProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "\u{21e6}", style: .plain, target: self, action: #selector(backAction))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(deleteAction))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        noteViewModel = viewModel?.editedNote
        self.textView.text = noteViewModel?.noteText
        self.navigationItem.rightBarButtonItem?.isEnabled = (noteViewModel != nil)
        if noteViewModel == nil {
            self.title = LocalizedString("newNoteControllerTitle")
            self.textView.becomeFirstResponder()
        } else {
            self.title = LocalizedString("noteControllerTitle")
        }
    }
    
    // MARK: - User actions

    @objc func deleteAction() {
        showAlert(message: "Remove this note?") { self.deleteNote() }
    }

    @objc func backAction() {
        self.textView.resignFirstResponder()
        guard !self.textView.text.isEmpty else {
            if noteViewModel != nil {
                showAlert(message: "Note is empty. Remove this note?") { self.deleteNote() }
            } else {
                dismissSelf()
            }
            return
        }
        
        if self.textView.text.hashValue != (noteViewModel?.noteText ?? "").hashValue {
            showAlert(message: "Save changes?") { self.saveAction() }
        } else {
            dismissSelf()
        }
    }
    
    // MARK: - Helpers

    func saveAction() {
        viewModel?.updateNote(withText: self.textView.text)
        dismissSelf()
    }
    
    func deleteNote() {
        viewModel?.deleleOpenedNote()
        dismissSelf()
    }
    
    func dismissSelf() {
        self.navigationController?.popViewController(animated: true)
    }

    func showAlert(message: String, handler: @escaping () -> Void) {
        let alertController = UIAlertController(title: "Attention", message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { _ in handler() }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in self.dismissSelf() }
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
}
