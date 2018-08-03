
import Foundation

protocol DataService: class {
    var numberOfNotes: Int { get }
    var onCompleteOperation: (Bool, Error?) -> Void { get set }
    
    func note(at indexPath: IndexPath) -> Note
    
    func addNote(withText text: String)
    func updateNote(withText text: String, at indexPath: IndexPath)
    func removeNote(at indexPath: IndexPath)
}
