//
//  LibraryView.swift
//  moledro
//
//  Created by Tyler Holewinski on 6/18/23.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import GoogleSignIn

struct LibraryView: View {
    @ObservedObject private var viewModel = LibraryViewModel()
    @State private var isPresentingBuilderSheet = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: createGridColumns(), spacing: 16) {
                    ForEach(viewModel.libraries) { library in
                        NavigationLink(destination: LibraryDetailView(library: library)) {
                            FirebaseStoreImageLoader(reference: Storage.storage().reference().child("\(library.id).jpg"), fallback: {
                                CardView(title: library.name, subtitle: "0 Books", image: Image(systemName: "books.vertical.circle"))
                            }) { uiImage in
                                CardView(title: library.name, subtitle: "0 Books", image: Image(uiImage: uiImage))
                            }
                        }
                    }
                }
                .padding()
            }
            
            .toolbar {
                Button {
                    isPresentingBuilderSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            .navigationTitle("My Libraries")
        }
        .onDisappear {
            viewModel.teardownListener()
        }
        .sheet(isPresented: $isPresentingBuilderSheet) {
            LibraryBuilderView()
        }
    }
    
    private func createGridColumns() -> [GridItem] {
        let columns: [GridItem] = [
            GridItem(.flexible(minimum: 0, maximum: .infinity), spacing: 16),
            GridItem(.flexible(minimum: 0, maximum: .infinity), spacing: 16),
        ]
        return columns
    }
}

struct LibraryGridItem: View {
    let text: String?
    @ViewBuilder let content: () -> Image
    
    var body: some View {
        VStack {
            content()
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 42, height: 42)
                .foregroundColor(.primary)
            
            if let text = text {
                Text(text)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .fontWeight(.bold)
                    .lineLimit(1)
                    .padding(.top, 8)
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.gray.opacity(0.5))
        }
    }
}

struct LibraryDetailView: View {
    let library: Library
    
    @Environment(\.presentationMode) var presentationMode
    @State var isAlertPresenting = false
    
    var body: some View {
        Form {
            Section {
                LabeledContent("Name", value: library.name)
                LabeledContent( "owner", value: library.ownerUID)
            }
            
            Section {
                Button("Delete Library") {
                    isAlertPresenting = true
                }
                .tint(.red)
            }
        }.confirmationDialog("Are you sure?", isPresented: $isAlertPresenting) {
            Button("Cancel", role: .cancel) {
                isAlertPresenting = false
            }
            Button("Delete", role: .destructive) {
                handleDelete()
            }
        } message: {
            Text("Are you sure you want to delete '\(library.name)'")
        }
    }
    
    func handleDelete() {
        let db = Firestore.firestore()
        
        db.document("libraries/\(library.id)").delete { err in
            print("libraries/\(library.id)")
            if let err = err {
                print(err.localizedDescription)
            }
            presentationMode.wrappedValue.dismiss()
        }
    }
}

struct CardView: View {
    var title: String
    var subtitle: String
    var image: Image
    
    var body: some View {
        VStack(alignment: .leading) {
            image
                .resizable()
                .scaledToFill()
                .frame(width: 150, height: 150)
                .cornerRadius(10)
            
            VStack(alignment: .leading) {
                Text(title)
                    .lineLimit(1)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .lineLimit(1)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.all, 8)
            
            Spacer()
        }
        .background(Color(UIColor.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 5)
        .padding()
    }
}
