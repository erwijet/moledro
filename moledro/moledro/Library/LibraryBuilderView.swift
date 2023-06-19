//
//  LibraryBuilderView.swift
//  moledro
//
//  Created by Tyler Holewinski on 6/18/23.
//

import SwiftUI
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore

struct LibraryBuilderView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @State private var libraryName = ""
    @State private var image: UIImage?
    @State private var isImagePickerPresenting = false
    
    private let storage = Storage.storage().reference()
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Library Details")) {
                    TextField("Library Name", text: $libraryName)
                }
                
                Section {
                    Button("Take Picture") {
                        isImagePickerPresenting = true
                    }
                    .sheet(isPresented: $isImagePickerPresenting) {
                        ImagePicker(image: $image, isPresented: $isImagePickerPresenting)
                    }
                    
                    if let image = image {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 200)
                    }
                }
            }
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Create") {
                    handleCreate()
                }.disabled(libraryName.isEmpty || image == nil)
            )
            .navigationTitle("Create Library")
        }
    }
    
    private func handleCreate() {
        guard let imageData = image?.jpegData(compressionQuality: 0.8), let uid = Auth.auth().currentUser?.uid else {
            return
        }
        
        let libraryRef = db.collection("libraries").addDocument(data: [
            "name": libraryName,
            "ownerUID": uid
        ])
        
        let imageName = "\(libraryRef.documentID).jpg"
        
        storage.child(imageName).putData(imageData, metadata: nil) { (_, error) in
            if let error = error {
                print("Error uploading image: \(error.localizedDescription)")
                return
            }
            
            presentationMode.wrappedValue.dismiss()
        }
    }
}
