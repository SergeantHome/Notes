
import XCTest
@testable import Homework_Notes_CoreData

class Homework_Notes_CoreDataTests: XCTestCase {
    
    var viewModel : NoteListViewModel!
    var mockDataservice: MockDataService!
    
    override func setUp() {
        super.setUp()
        mockDataservice = MockDataService()
        viewModel = NoteListViewModel(dataService: mockDataservice)
    }
    
    override func tearDown() {
        viewModel = nil
        mockDataservice = nil
        super.tearDown()
    }
    
    func testAddNote() {
        let initCount = viewModel.numberOfNotes
        let testNote = "Test Note"
        viewModel.startEdit(at: nil)
        viewModel.updateNote(withText: testNote)
        XCTAssertEqual(viewModel.numberOfNotes, initCount + 1, "Expected one more note in list")
        XCTAssertEqual(viewModel.note(at: IndexPath(row: 0, section: 0)).noteText, testNote, "Expected note text: \(testNote)")
    }
    
}
