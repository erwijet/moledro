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
    
    @State private var isCameraPresenting = false
    @State private var isPhotoLibraryPresenting = false
    
    @State private var isLoading = false
    
    private let storage = Storage.storage().reference()
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationView {
            ZStack {
                Form {
                    Section(header: Text("Library Details")) {
                        TextField("Library Name", text: $libraryName)
                    }
                    
                    Section {
                        Button("Open Camera") {
                            isCameraPresenting = true
                        }
                        .sheet(isPresented: $isCameraPresenting) {
                            ImagePicker(sourceType: .camera, image: $image)
                        }
                        
                        Button("Choose Image") {
                            isPhotoLibraryPresenting = true
                        }
                        .sheet(isPresented: $isPhotoLibraryPresenting) {
                            ImagePicker(sourceType: .photoLibrary, image: $image)
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
                    }.disabled(libraryName.isEmpty || image == nil || isLoading)
                )
                .navigationTitle("Create Library")
                
                if isLoading {
                    Color.black.opacity(0.4)
                        .edgesIgnoringSafeArea(.all)
                        .onTapGesture {} // Prevents tap events on the underlying content
                    
                    
                    VStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .foregroundColor(.accentColor)
                    }
                    .frame(width: 40, height: 40)
                    .background(.gray)
                    .cornerRadius(10)
                }
            }
        }
    }
    
    private func handleCreate() {
        guard let imageData = image?.jpegData(compressionQuality: 0.8), let uid = Auth.auth().currentUser?.uid else {
            return
        }
        
        isLoading = true
        
        let libraryRef = db.collection("libraries").document()
        let imageName = "\(libraryRef.documentID).jpg"
        
        storage.child(imageName).putData(imageData, metadata: nil) { (_, error) in
            if let error = error {
                print("Error uploading image: \(error.localizedDescription)")
                return
            }
            
            libraryRef.setData([
                "name": libraryName,
                "ownerUID": uid,
                "books": [Book]()
            ])
            
            presentationMode.wrappedValue.dismiss()
        }
    }
}
