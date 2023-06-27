//
//  UserLibrariesViewModel.swift
//  moledro
//
//  Created by Tyler Holewinski on 6/18/23.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseAuth

class UserLibrariesViewModel: ObservableObject {
    @Published var libraries = [Library]()
    private var db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    init() {
        setupListener()
    }
    
private func setupListener() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        listener = db.collection("libraries").whereField("ownerUID", isEqualTo: uid).addSnapshotListener { querySnapshot, error in
            guard let documents = querySnapshot?.documents else { return }
            
            self.libraries = documents.map {
                let data = $0.data()
                return Library(id: $0.documentID, name: data["name"] as? String ?? "", ownerUID: data["ownerUID"] as? String ?? "", books: (data["books"] as? [[String: Any]])?.compactMap { Book(dict: $0 ) } ?? [Book]() )
            }
        }
    }
    
    func teardownListener() {
        listener?.remove()
        listener = nil
    }
}
