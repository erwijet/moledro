//
//  Book.swift
//  moledro
//
//  Created by Tyler Holewinski on 6/19/23.
//

import Foundation

struct Book: Codable, Identifiable, Hashable {
    let id: UUID // assigned when init'ed
    let isbn: String
    let title: String
    let author: String
    let ownerUID: String
    let image: String?
    let ddc: String?
    let subjects: [String]
    let tags: [String]
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension Book {
    init(from bookInfo: BookInfo, withOwner ownerUID: String) {
        id = UUID()
        isbn = bookInfo.isbn
        title = bookInfo.title
        author = bookInfo.author
        image = bookInfo.image
        ddc = bookInfo.classification?.ddc
        subjects = bookInfo.classification?.fast_subjects ?? [String]()
        tags = [String]()
        
        
        self.ownerUID = ownerUID
    }
    
    init?(dict: [String: Any]) {
         guard let idString = dict["id"] as? String,
               let id = UUID(uuidString: idString),
               let title = dict["title"] as? String,
               let author = dict["author"] as? String,
               let isbn = dict["isbn"] as? String,
               let subjects = dict["subjects"] as? [String],
               let tags = dict["tags"] as? [String],
               let ownerUID = dict["ownerUID"] as? String else {
                   return nil
         }
        
        self.id = id
        self.isbn = isbn
        self.title = title
        self.author = author
        self.ownerUID = ownerUID
        self.subjects = subjects
        self.tags = tags
        
        self.ddc = dict["ddc"] as? String
        self.image = dict["image"] as? String
     }
}

struct BookInfoClassification: Codable {
    let ddc: String;
    let fast_subjects: [String];
}

struct BookInfo: Codable {
    let title: String
    let author: String
    let isbn: String
    let image: String?
    let classification: BookInfoClassification?;
}


extension BookInfo {
    init(from book: Book) {
        self.title = book.title
        self.author = book.author
        self.isbn = book.isbn
        self.image = book.image
        
        self.classification = book.ddc != nil ? BookInfoClassification(ddc: book.ddc!, fast_subjects: book.subjects) : nil
        
    }
}

struct CoelhoResponse: Codable {
    let ok: Bool
    let result: BookInfo
}
