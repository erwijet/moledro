//
//  Library.swift
//  moledro
//
//  Created by Tyler Holewinski on 6/18/23.
//

import Foundation


struct LibrarySettings: Codable {
    enum LibrarySettingsSortBy: String, Codable {
        case alphaByAuthor = "ALPHA_BY_AUTHOR"
        case alphaByTitle = "ALPHA_BY_TITLE"
        case ddcThenAlphaByAuthor = "DCC_THEN_ALPHA_BY_AUTHOR"
        case ddcThenAlphaByTitle = "DCC_THEN_ALPHA_BY_TITLE"
    }
    
    var showDDC: Bool
    var showFastSubjects: Bool
    var showTags: Bool
    var showPreview: Bool
    var sortBy: LibrarySettingsSortBy
    
    init(showDDC: Bool, showFastSubjects: Bool, showTags: Bool, showPreview: Bool, sortBy: LibrarySettingsSortBy) {
        self.showDDC = showDDC
        self.showFastSubjects = showFastSubjects
        self.showTags = showTags
        self.showPreview = showPreview
        self.sortBy = sortBy
    }
    
    init() {
        self.showDDC = false
        self.showFastSubjects = false
        self.showTags = true
        self.showPreview = true
        self.sortBy = .alphaByAuthor
    }
    
    init(dict: [String: Any]) {
        self.showDDC = dict["showDDC"] as? Bool ?? false
        self.showFastSubjects = dict["showFastSubjects"] as? Bool ?? false
        self.showTags = dict["showTags"] as? Bool ?? true
        self.showPreview = dict["showPreview"] as? Bool ?? true
        self.sortBy = (dict["sortBy"] as? String).flatMap { LibrarySettingsSortBy(rawValue: $0) } ?? .alphaByAuthor
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        showDDC = try container.decode(Bool.self, forKey: .showDDC)
        showFastSubjects = try container.decode(Bool.self, forKey: .showFastSubjects)
        showTags = try container.decode(Bool.self, forKey: .showTags)
        showPreview = try container.decode(Bool.self, forKey: .showPreview)
        sortBy = try container.decode(LibrarySettingsSortBy.self, forKey: .sortBy)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(showDDC, forKey: .showDDC)
        try container.encode(showFastSubjects, forKey: .showFastSubjects)
        try container.encode(showPreview, forKey: .showPreview)
        try container.encode(showTags, forKey: .showTags)
        try container.encode(sortBy, forKey: .sortBy)
    }
    
    private enum CodingKeys: String, CodingKey {
        case showDDC
        case showFastSubjects
        case showTags
        case showPreview
        case sortBy
    }
}

struct Library: Codable, Identifiable, Hashable {
    static func == (lhs: Library, rhs: Library) -> Bool {
        lhs.id == rhs.id
    }
    
    let id: String
    let name: String
    let ownerUID: String
    
    var settings: LibrarySettings
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
