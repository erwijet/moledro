//
//  BookDetailView.swift
//  moledro
//
//  Created by Tyler Holewinski on 6/26/23.
//

import SwiftUI

struct BookDetailView: View {
    let book: Book;
    
    @State private var draftTitle: String
    @State private var draftAuthor: String
    @State private var draftImage: String?
    @State private var draftSubjects: [String]
    @State private var draftTags: [String]
    
    init(book: Book) {
        self.book = book
        _draftTitle = State(initialValue: book.title)
        _draftAuthor = State(initialValue: book.author)
        _draftImage = State(initialValue: book.image)
        _draftSubjects = State(initialValue: book.subjects)
        _draftTags = State(initialValue: book.tags)
    }
    
    var body: some View {
        Form {
            Section() {
                HStack(alignment: .top) {
                    if let imageURL = book.image, let url = URL(string: imageURL)! {
                        AsyncImage(url: url) { image in
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
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .leading) {
                        BookDetailList(book: book)
                    }
                }
            }
            
            Section(content: {
                TrailingLabeledTextView(title: "Title", value: $draftTitle)
                TrailingLabeledTextView(title: "Author", value: $draftAuthor)
            }, footer: {
                Text("Edit these values to customize this book")
            })
            
            Section("Tags") {
                NavigationLink(destination: Text("tags")) {
                    WrappingHStack(horizontalSpacing: 8) {
                        if book.tags.count > 0 {
                            ForEach(book.tags, id: \.self) {
                                ChipView(title: $0, backgroundColor: .teal)
                            }.frame(minWidth: 50)
                        } else {
                            Text("None")
                        }
                    }
                }
            }
            
            Section("Subjects") {
                NavigationLink(destination: Text("hi")) {
                    WrappingHStack(horizontalSpacing: 8) {
                        if book.subjects.count > 0 {
                            ForEach(book.subjects, id: \.self) {
                                ChipView(title: $0, backgroundColor: .indigo)
                            }.frame(minWidth: 50)
                        } else {
                            Text("None")
                        }
                    }
                }
            }
        }
        .foregroundColor(.primary)
        .navigationTitle($draftTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct BookDetailList: View {
    
    let book: Book
    
    var body: some View {
        VStack(alignment: .leading) {
            Divider()
            DetailItem(title: "Owner", value: "@erwijet")
            Divider()
            DetailItem(title: "ISBN", value: book.isbn)
            Divider()
            DetailItem(title: "Added", value: "4 Months Ago")
            Divider()
        }
    }
}

private struct DetailItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
            Text(value)
                .font(.subheadline)
        }
    }
}

struct TrailingLabeledTextView: View {
    let title: String
    @Binding var value: String
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            TextField(title, text: $value).multilineTextAlignment(.trailing)
        }
    }
}
