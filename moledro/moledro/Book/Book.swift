//
//  Book.swift
//  moledro
//
//  Created by Tyler Holewinski on 6/19/23.
//

import Foundation

struct Book: Codable, Identifiable, Hashable {
    let id: String // isbn
    let title: String
    let author: String
    let binding: String
    let description: String
    let publishDate: Date
    let ownerUID: String
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct CoelhoResponse: Codable {
    struct BookInfo: Codable {
        let title: String
        let author: String
        let pub_date: String
        let binding: String
        let isbn: String
        let img: String?
    }
    
    let ok: Bool
    let result: BookInfo
}
