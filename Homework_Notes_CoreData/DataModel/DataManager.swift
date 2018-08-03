
import Foundation
import CoreData

class DataManager: NSObject, DataService {
    
    static let shared = DataManager()
    
    private override init () {
        super.init()
        do {
            try fetchedResultsController.performFetch()
        } catch {
            showFatalError("Failed to initialize FetchedResultsController: \(error)")
        }
        
        NetworkManager.getAllNotes { (notesArray, error) in
            guard error == nil else {
                print(error!.localizedDescription)
                self.onCompleteOperation(false, error); return
            }
            self.updateNotesWith(notesArray)
        }
    }
    
    private lazy var fetchedResultsController: NSFetchedResultsController<Note> = {
        let request = NSFetchRequest<Note>(entityName: "Note")
        let idSort = NSSortDescriptor(key: "noteId", ascending: true)
        request.sortDescriptors = [idSort]
        
        let moc = self.persistentContainer.viewContext
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
    }()
    
    var onCompleteOperation: (Bool, Error?) -> Void = { _, _ in }

    // MARK: - Core Data stack
    
    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Homework_Notes_CoreData")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                showFatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                showFatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    // MARK: - Data Service
    
    var numberOfNotes: Int {
        let sections = fetchedResultsController.sections
        return sections?.first?.numberOfObjects ?? 0
    }
    
    func note(at indexPath: IndexPath) -> Note {
        return fetchedResultsController.object(at: indexPath)
    }
    
    func addNote(withText text: String) {
        NetworkManager.createNote(text) { (noteResponse, error) in
            guard error == nil else {
                self.onCompleteOperation(false, error)
                return
            }
            
            guard let newNoteID = noteResponse?.noteId else {
                self.onCompleteOperation(false, nil); return
            }
            
            self.performUpdatingContextBlock { context in
                let noteEntity = NSEntityDescription.insertNewObject(forEntityName: "Note", into: context) as! Note
                noteEntity.noteId = Int64(newNoteID)
                noteEntity.noteText = text //noteResponse?.noteText
                noteEntity.noteHash = Int64(text.hashValue)
            }
        }
    }
    
    func updateNote(withText text: String, at indexPath: IndexPath) {
        self.update(note(at: indexPath), withText: text)
    }
    
    func removeNote(at indexPath: IndexPath) {
        self.remove(note(at: indexPath))
    }
    
    // MARK: - Private

    private func update(_ noteEntity: Note, withText text: String) {
        NetworkManager.udateNote(withID: Int(noteEntity.noteId), newText: text) { (noteResponse, error) in
            guard error == nil else {
                self.onCompleteOperation(false, error)
                return
            }
            
            self.performUpdatingContextBlock { _ in
                noteEntity.noteText = text //noteResponse?.noteText
                noteEntity.noteHash = Int64(text.hashValue)
            }
        }
    }

    private func remove(_ noteEntity: Note) {
        NetworkManager.deleteNote(withID: Int(noteEntity.noteId)) { (error) in
            guard error == nil else {
                self.onCompleteOperation(false, error)
                return
            }
            
            self.performUpdatingContextBlock { context in
                context.delete(noteEntity)
            }
        }
    }
    
    private func performUpdatingContextBlock(_ handler: (NSManagedObjectContext) -> Void) {
        let context = self.persistentContainer.viewContext
        context.performAndWait {
            do {
                handler(context)
                try context.save()
            } catch {
                print(error)
                self.onCompleteOperation(false, error)
            }
        }
    }
    
    private func updateNotesWith(_ notesArray: [NoteResponse]?) {
        guard let notesArray = notesArray else {
            self.onCompleteOperation(false, nil); return
        }
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.parent = self.persistentContainer.viewContext
        context.performAndWait {
            do {
                let request: NSFetchRequest<Note> = Note.fetchRequest()
                let storedNotesID = try request.execute().map { $0.noteId }
                let receivedNotesID = notesArray.map { Int64($0.noteId) }
                let needRemoveNotesWithID = Set(storedNotesID).subtracting(Set(receivedNotesID))
                for note in notesArray {
                    request.predicate = NSPredicate(format: "noteId == %@", note.noteId as NSNumber)
                    var noteEntity: Note! = try request.execute().first
                    if noteEntity == nil {
                        noteEntity = NSEntityDescription.insertNewObject(forEntityName: "Note", into: context) as! Note
                        noteEntity.noteId = Int64(note.noteId)
                    }
                    if noteEntity.noteHash != Int64(note.noteText.hashValue) {
                        noteEntity.noteText = note.noteText
                        noteEntity.noteHash = Int64(note.noteText.hashValue)
                    }
                }
                for noteID in needRemoveNotesWithID {
                    request.predicate = NSPredicate(format: "noteId == %@", noteID as NSNumber)
                    for noteEntity in try request.execute() {
                        context.delete(noteEntity)
                    }
                }

                try save(in: context)

            } catch {
                print(error)
                self.onCompleteOperation(false, error)
            }
        }
    }

    private func save(in context: NSManagedObjectContext) throws {
        if context.hasChanges {
            try context.save()
            if let parentContext = context.parent {
                var parentContextError: Error? = nil
                parentContext.performAndWait {
                    if parentContext.hasChanges {
                        do {
                            try parentContext.save()
                        } catch {
                            parentContextError = error
                        }
                    }
                }
                guard parentContextError == nil else { throw parentContextError! }
            }
        } else {
            self.onCompleteOperation(false, nil)
        }
    }
}

extension DataManager: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.onCompleteOperation(true, nil)
    }
}
