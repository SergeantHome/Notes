
import Foundation

typealias JSON = [String: AnyObject]

class NetworkManager: NSObject {
    
    static let baseURL = URL(string: "https://private-9aad-note10.apiary-mock.com/")
    
    static let notesURL = URL(string: "notes", relativeTo: baseURL)
    
    static let shared = NetworkManager()
    
    var session: URLSession!
    
    private override init () {
        super.init()
        let sessionConfiguration = URLSessionConfiguration.default
        self.session = URLSession(configuration: sessionConfiguration, delegate: self , delegateQueue: nil)
    }
    
    class func createNote(_ text: String, completionHandler: @escaping (NoteResponse?, Error?) -> Void) {
        guard let url = notesURL else { completionHandler(nil, nil); return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let parameters = ["title" : text]
        request.httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard error == nil else { completionHandler(nil, error); return }
            if let httpResponse = response as? HTTPURLResponse {
                print(httpResponse.statusCode)
            }
            guard data != nil, let jsonObject = try? JSONSerialization.jsonObject(with: data!, options: []),
                let json = jsonObject as? JSON, let note = NoteResponse(json: json) else {
                    print("Bad Data")
                    completionHandler(nil, nil); return
            }
            completionHandler(note, nil)
        }
        
        task.resume()
    }
    
    class func udateNote(withID noteId:Int, newText text: String, completionHandler: @escaping (NoteResponse?, Error?) -> Void) {
        guard let url = notesURL?.appendingPathComponent("/\(noteId)") else { completionHandler(nil, nil); return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let parameters = ["title" : text]
        request.httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard error == nil else { completionHandler(nil, error); return }
            if let httpResponse = response as? HTTPURLResponse {
                print(httpResponse.statusCode)
            }
            guard data != nil, let jsonObject = try? JSONSerialization.jsonObject(with: data!, options: []),
                let json = jsonObject as? JSON, let note = NoteResponse(json: json) else {
                    print("Bad Data")
                    completionHandler(nil, nil); return
            }
            completionHandler(note, nil)
        }
        
        task.resume()
    }

    class func deleteNote(withID noteId:Int, completionHandler: @escaping (Error?) -> Void) {
        guard let url = notesURL?.appendingPathComponent("/\(noteId)") else { completionHandler(nil); return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard error == nil else { completionHandler(error); return }
            if let httpResponse = response as? HTTPURLResponse {
                print(httpResponse.statusCode)
            }
            completionHandler(nil)
        }
        
        task.resume()
    }

    class func getAllNotes(completionHandler: @escaping ([NoteResponse]?, Error?) -> Void) {
        guard let url = notesURL else { completionHandler(nil, nil); return }
        
        let task = NetworkManager.shared.session.dataTask(with: url) { (data, response, error) in
            guard error == nil else { completionHandler(nil, error); return }
            if let httpResponse = response as? HTTPURLResponse {
                print(httpResponse.statusCode)
            }
            guard data != nil, let jsonObject = try? JSONSerialization.jsonObject(with: data!, options: []), let jsonArray = jsonObject as? [JSON] else {
                completionHandler(nil, nil); return
            }
            let notesArray = jsonArray.compactMap { (json) -> NoteResponse? in
                guard let note = NoteResponse(json: json) else {
                    print("Bad JSON: \(json)")
                    return nil
                }
                return note
            }
            completionHandler(notesArray, nil)
        }
        task.resume()
    }
}

extension NetworkManager: URLSessionDelegate {
    
}

// MARK: - Responses

struct NoteResponse {
    let noteId: Int
    let noteText: String
}

extension NoteResponse {
    
    init!(json: JSON) {
        guard let noteId = json["id"] as? Int else { return nil }
        guard let noteText = json["title"] as? String else { return nil }
        self.noteId = noteId
        self.noteText = noteText
    }
}
