//
//  LibraryBooksView.swift
//  moledro
//
//  Created by Tyler Holewinski on 6/24/23.
//

import SwiftUI

import FirebaseFirestore
import FirebaseAuth

struct NavigationLazyView<Content: View>: View {
    let build: () -> Content
    init(_ build: @autoclosure @escaping () -> Content) {
        self.build = build
    }
    var body: Content {
        build()
    }
}

struct LibraryBooksView: View {
    let libraryId: String
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
 
    @StateObject private var libraryViewModel: LibraryViewModel = LibraryViewModel()
    
    @State private var searchQuery = ""
    @State private var isShowingLibrarySettings = false
    @State private var isShowingScanner = false
    
    var body: some View {
        if let library = libraryViewModel.library {
            NavigationStack {
                List(library.books.filter {book in
                    searchQuery.isEmpty || book.title.localizedCaseInsensitiveContains(searchQuery)
                }, id: \.id) { book in
                    NavigationLink(
                        destination: BookInfoDetailView(bookInfo: BookInfo.init(from: book)).navigationTitle(book.title),
                        label: {
                            Text(book.title)
                        }
                    ) .swipeActions {
                        Button("Delete") {
                            libraryViewModel.removeBook(id: book.id)
                        }.tint(.red)
                    } .contextMenu(menuItems: {
                        Button {
                            openURL(URL(string: "https://bookscouter.com/bulk-comparison?isbn=\(book.isbn)")!)
                        } label: {
                            Label("Open in Bookscouter", systemImage: "dollarsign.arrow.circlepath")
                        }
                    }, preview: {
                        if let img = book.img {
                            AsyncImage(url: URL(string: img)!) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .cornerRadius(10)
                            } placeholder: {
                                Image(systemName: "photo")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            Text("No Preview Avalible")
                        }
                    })
                }
                .searchable(text: $searchQuery)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isShowingLibrarySettings = true
                    } label: {
                        Image(systemName: "gear")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            isShowingScanner = true
                        } label: {
                            Label("Scan Barcode", systemImage: "barcode.viewfinder")
                        }
                        
                        Button {
                            // Handle enter manually action
                        } label: {
                            Label("Enter Manually", systemImage: "square.and.pencil")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .navigationTitle(libraryViewModel.library?.name ?? "")
            .sheet(isPresented: $isShowingLibrarySettings) {
                if let library = libraryViewModel.library {
                    LibrarySettingsView(library: library, libraryDidDelete: {
                        isShowingLibrarySettings = false
                        dismiss()
                    })
                }
            }
            .sheet(isPresented: $isShowingScanner) {
                IsbnScanAndQueryView { resp in
                    guard let result = resp?.result, let uid = Auth.auth().currentUser?.uid else { return }
                    
                    onAddBook(book: .init(from: result, withOwner: uid))
                    
                } willDismiss: {
                    isShowingScanner = false
                }
            }
        } else {
            ProgressView()
                .onAppear {
                    libraryViewModel.loadLibrary(libraryId: libraryId)
                }
        }
    }
    
    func onAddBook(book: Book) {
        libraryViewModel.addBook(book)
    }
}
