//
//  LibraryViewModel.swift
//  moledro
//
//  Created by Tyler Holewinski on 6/25/23.
//

import SwiftUI
import FirebaseFirestore

class LibraryViewModel: ObservableObject {
    @Published var library: Library?
    
    private var libraryId: String?
    private let db = Firestore.firestore()
    
    func loadLibrary(libraryId: String) {
        // Fetch the library document from Firestore and assign it to the library property
        
        let ref = db.collection("libraries").document(libraryId)
        
        ref.getDocument { [weak self] snapshot, error in
            guard let snapshot = snapshot, snapshot.exists, let data = snapshot.data() else { return }
            
            let id = snapshot["id"] as? String ?? ""
            let name = snapshot["name"] as? String ?? ""
            let ownerUID = snapshot["ownerUID"] as? String ?? ""
            
            var books: [Book] = []
            
            if let bookData = data["books"] as? [[String: Any]] {
                books = bookData.compactMap { bookDict in
                    return Book(dict: bookDict)
                }
            }
            
            self?.library = Library(id: id, name: name, ownerUID: ownerUID, books: books)
            self?.libraryId = libraryId
        }
    }
    
    func addBook(_ book: Book) {
        library?.books.append(book)
        
        guard let dict = try? library?.toDictionary(), let libraryId = self.libraryId else { return }
        db.collection("libraries").document(libraryId).setData(dict)
    }
    
    func removeBook(id: UUID) {
        library?.books.removeAll { $0.id == id }
        
        guard let dict = try? library?.toDictionary(), let libraryId = self.libraryId else { return }
        db.collection("libraries").document(libraryId).setData(dict)
    }
}
