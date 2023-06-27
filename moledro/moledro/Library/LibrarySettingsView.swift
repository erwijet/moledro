//
//  LibrarySettingsView.swift
//  moledro
//
//  Created by Tyler Holewinski on 6/25/23.
//

import SwiftUI
import FirebaseFirestore

struct LibrarySettingsView: View {
    let library: Library
    
    let libraryDidDelete: () -> Void
    
    @State private var isShowingDeleteAlert = false
    
    var body: some View {
        Form {
            Section {
                LabeledContent("Name", value: library.name)
                LabeledContent("Owner", value: library.ownerUID)
            }
            
            Section {
                Button("Delete Library") {
                    isShowingDeleteAlert = true
                }.tint(.red)
            }
        }.alert(isPresented: $isShowingDeleteAlert) {
            Alert(
                title: Text("Are you sure?"),
                message: Text("Are you sure you want to delete '\(library.name)'"),
                primaryButton: .destructive(Text("Delete")) {
                    handleDelete()
                },
                secondaryButton: .cancel(Text("Cancel"))
            )
        }
    }
    
    func handleDelete() {
        let db = Firestore.firestore()
        
        db.document("libraries/\(library.id)").delete { error in
            if let error = error {
                print(error.localizedDescription)
            }
            
            libraryDidDelete()
        }
    }
}


