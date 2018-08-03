//
//  MockDataService.swift
//  Homework_Notes_CoreDataTests
//
//  Created by Serhii Riabchun on 8/2/18.
//  Copyright © 2018 Self Education. All rights reserved.
//

import Foundation

struct Note {
    var noteText: String?
}

class MockDataService: DataService {
    private var stubNoteList = [Note]()
    
    var numberOfNotes: Int { return stubNoteList.count }
    var onCompleteOperation: (Bool, Error?) -> Void = { _, _ in }
    
    func note(at indexPath: IndexPath) -> Note {
        return stubNoteList[indexPath.row]
    }
    
    func addNote(withText text: String) { stubNoteList.append(Note(noteText: text)) }
    func updateNote(withText text: String, at indexPath: IndexPath) { stubNoteList[indexPath.row].noteText = text }
    func removeNote(at indexPath: IndexPath) { stubNoteList.remove(at: indexPath.row) }
}
