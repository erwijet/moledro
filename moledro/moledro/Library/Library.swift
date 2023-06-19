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
    let ownerUID : String
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
