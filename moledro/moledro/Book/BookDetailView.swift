//
//  BookInfoDetailView.swift
//  moledro
//
//  Created by Tyler Holewinski on 6/26/23.
//

import SwiftUI

struct BookInfoDetailView: View {
    let book: Book
    
    var body: some View {
        VStack {
            Form {
                HStack {
                    NavigationLink(destination: Text("hi")) {
                        HStack(alignment: .top) {
                            Text("Subjects")
                            Spacer()
                            
                            ForEach(book.subjects, id: \.self) {
                                ChipView(title: $0, backgroundColor: .indigo)
                            }.frame(minWidth: 50)
                            
                        }
                    }
                    
                    Spacer()
                    
                    if let imageURL = bookInfo.image, let url = URL(string: imageURL)! {
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
                }
                
                Text(bookInfo.title)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                Section() {
                    LabeledContent("Author", value: bookInfo.author)
                    LabeledContent("ISBN", value: bookInfo.isbn)
                }
                
            } .scrollContentBackground(.hidden)
            
        }
        .foregroundColor(.primary)
    }
}
