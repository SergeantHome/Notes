
import Foundation


enum NoteListState {
    case updating
    case listed
    case editing(at: IndexPath?)
    case error(Error)
}

// MARK: - Protocols

protocol NoteProtocol {
    var noteText: String { get }
}

protocol NoteListProtocol: class {
    var listState: NoteListState { get }
    var numberOfNotes: Int { get }

    var onDataUpdated: () -> Void { get set }
    var onLoadingStatusChange: (Bool) -> Void { get set }
    var onStartEditing: (IndexPath?) -> Void { get set }
    var onGotError: (Error?) -> Void { get set }
    
    func note(at indexPath: IndexPath) -> NoteProtocol
    
    func startEdit(at indexPath: IndexPath?)
    func delele(at indexPath: IndexPath)
    func updateNote(withText text: String)
    
    init(dataService: DataService)
}

extension NoteListProtocol {
    func deleleOpenedNote() {
        switch listState {
        case let .editing(indexPath) where indexPath != nil:
            delele(at: indexPath!)
        default:
            return
        }
    }
    
    var editedNote: NoteProtocol? {
        switch listState {
        case let .editing(indexPath) where indexPath != nil:
            return note(at: indexPath!)
        default:
            return nil
        }
    }
}

// MARK: - Implementations

struct NoteViewModel: NoteProtocol {
    let noteText: String
}

class NoteListViewModel: NoteListProtocol {
    private let dataService: DataService
    
    var listState: NoteListState {
        didSet {
            switch listState {
            case .updating:
                onLoadingStatusChange(true)
            case .listed:
                onLoadingStatusChange(false)
            case let .editing(at: indexPath):
                onStartEditing(indexPath)
            case let .error(error):
                onGotError(error)
            }
        }
    }
    
    var onDataUpdated: () -> Void = {}
    var onLoadingStatusChange: (Bool) -> Void = { _ in }
    var onStartEditing: (IndexPath?) -> Void = { _ in }
    var onGotError: (Error?) -> Void = { _ in }

    required init(dataService: DataService) {
        self.listState = .updating
        self.dataService = dataService
        self.dataService.onCompleteOperation = { [weak self] isDataUpdated, error in
            if isDataUpdated { self?.onDataUpdated() }
            self?.listState = .listed
            if error != nil { self?.listState = .error(error!) }
        }
    }
    
    private func add(note: NoteProtocol) {
        self.listState = .updating
        dataService.addNote(withText: note.noteText)
    }
    private func update(note: NoteProtocol, at indexPath: IndexPath) {
        self.listState = .updating
        dataService.updateNote(withText: note.noteText, at: indexPath)
    }
    
    var numberOfNotes: Int {
        return dataService.numberOfNotes
    }
    
    func note(at indexPath: IndexPath) -> NoteProtocol {
        let note = dataService.note(at: indexPath)
        return NoteViewModel(noteText: note.noteText ?? "(Empty note)")
    }
    
    func startEdit(at indexPath: IndexPath?) {
        self.listState = .editing(at: indexPath)
    }
    
    func updateNote(withText text: String) {
        switch listState {
        case let .editing(indexPath):
            if let indexPath = indexPath {
                update(note: NoteViewModel(noteText: text), at: indexPath)
            } else {
                add(note: NoteViewModel(noteText: text))
            }
        default:
            return
        }
    }
    
    func delele(at indexPath: IndexPath) {
        self.listState = .updating
        dataService.removeNote(at: indexPath)
    }
    
}
