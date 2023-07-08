//
//  BookGalleryItemView.swift
//  moledro
//
//  Created by Tyler Holewinski on 7/8/23.
//

import SwiftUI

struct BookGalleryItemView: View {
    let book: Book
    let libraryViewModel: LibraryViewModel
    
    var body: some View {
        
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Spacer()
                    
                    Text(book.title)
                        .font(.headline)
                    
                    Text(book.author)
                        .font(.subheadline)
                    
                    
                    if let ddc = book.ddc, libraryViewModel.library?.settings.showDDC ?? false, libraryViewModel.library?.settings.showPreview ?? false {
                        Spacer()
                        ChipView(title: "DDC:\(ddc)", backgroundColor: .accentColor)
                    }
                    
                    Spacer()
                }
                
                Spacer()
                
                if libraryViewModel.library?.settings.showPreview ?? true {
                    if let image = book.image {
                        VStack {
                            AsyncImage(url: URL(string: image)!) { image in
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
                        .frame(width: 120, height: 120)
                    }
                }
                
                if let ddc = book.ddc, libraryViewModel.library?.settings.showDDC ?? false, !(libraryViewModel.library?.settings.showPreview ?? false) {
                    ChipView(title: "DDC:\(ddc)", backgroundColor: .accentColor)
                }
            }
            
            if libraryViewModel.library?.settings.showFastSubjects ?? false || libraryViewModel.library?.settings.showTags ?? false {
                Spacer()
            }
            
            WrappingHStack(horizontalSpacing: 8) {
                if libraryViewModel.library?.settings.showTags ?? false {
                    ForEach(book.tags, id: \.self) {
                        ChipView(title: $0, backgroundColor: .mint)
                    }.frame(minWidth: 50)
                }
                
                if libraryViewModel.library?.settings.showFastSubjects ?? false {
                    ForEach(book.subjects, id: \.self) {
                        ChipView(title: $0, backgroundColor: .indigo)
                    }.frame(minWidth: 50)
                }
            }
            
            Spacer()
        }
    }
}
