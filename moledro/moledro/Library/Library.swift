//
//  Library.swift
//  moledro
//
//  Created by Tyler Holewinski on 6/18/23.
//

import Foundation

struct Library: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let ownerUID: String
    var books: [Book]
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    func toDictionary() throws -> [String: Any] {
        let encoder = JSONEncoder()
        let data = try encoder.encode(self)
        
        guard let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
            throw NSError(domain: "ConversionError", code: -1, userInfo: nil)
        }
        
        return dictionary
    }
}
