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
    let binding: String
    let publishDate: String
    let ownerUID: String
    let img: String?
    
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
        binding = bookInfo.binding
        publishDate = bookInfo.pub_date
        img = bookInfo.img
        
        self.ownerUID = ownerUID
    }
    
    init?(dict: [String: Any]) {
         guard let idString = dict["id"] as? String,
               let id = UUID(uuidString: idString),
               let title = dict["title"] as? String,
               let author = dict["author"] as? String,
               let binding = dict["binding"] as? String,
               let isbn = dict["isbn"] as? String,
               let publishDate = dict["publishDate"] as? String,
               let ownerUID = dict["ownerUID"] as? String else {
                   return nil
         }
         
         self.id = id
         self.isbn = isbn
         self.title = title
         self.author = author
         self.binding = binding
         self.publishDate = publishDate
         self.ownerUID = ownerUID
         self.img = dict["img"] as? String
     }
}

struct BookInfo: Codable {
    let title: String
    let author: String
    let pub_date: String
    let binding: String
    let isbn: String
    let img: String?
}

extension BookInfo {
    init(from book: Book) {
        self.title = book.title
        self.author = book.author
        self.pub_date = book.publishDate
        self.binding = book.binding
        self.isbn = book.isbn
        self.img = book.img
    }
}

struct CoelhoResponse: Codable {
    let ok: Bool
    let result: BookInfo
}
