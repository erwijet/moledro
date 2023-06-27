//
//  BookInfoDetailView.swift
//  moledro
//
//  Created by Tyler Holewinski on 6/26/23.
//

import SwiftUI

struct BookInfoDetailView: View {
    let bookInfo: BookInfo
    
    var body: some View {
        VStack {
            Form {
                if let imageURL = bookInfo.img, let url = URL(string: imageURL) {
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
                
                Text(bookInfo.title)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                Section() {
                    LabeledContent("Author", value: bookInfo.author)
                    LabeledContent("Pub Date", value: bookInfo.pub_date)
                    LabeledContent("Binding", value: bookInfo.binding)
                    LabeledContent("ISBN", value: bookInfo.isbn)
                }
                
            } .scrollContentBackground(.hidden)
            
        }
        .foregroundColor(.primary)
    }
}
