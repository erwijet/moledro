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
            
            self?.library = Library(
                id: snapshot.documentID,
                name: snapshot["name"] as? String ?? "",
                ownerUID: snapshot["ownerUID"] as? String ?? "",
                settings: (data["settings"] as? [String: Any]).flatMap { LibrarySettings(dict: $0) } ?? LibrarySettings(),
                books: (data["books"] as? [[String: Any]])?.compactMap { Book(dict: $0) } ?? [Book]()
            )
            
            self?.libraryId = libraryId
        }
    }
    
    func addBook(_ book: Book) {
        library?.books.append(book)
        commitLibrary()
    }
    
    func removeBook(id: UUID) {
        library?.books.removeAll { $0.id == id }
        commitLibrary()
    }
    
    func setSettings(settings: LibrarySettings) {
        library?.settings = settings
        commitLibrary()
    }
    
    private func commitLibrary() {
        guard let dict = try? library?.toDictionary(), let libraryId = self.libraryId else { return }
        db.collection("libraries").document(libraryId).setData(dict)
    }
}
