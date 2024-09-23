//
//  Elemental.swift
//  ElementalFramework
//
//  Created by Rizky Azmi Swandy on 21/09/24.
//

import Foundation

struct Element: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let emoji: String
    let language: String?
    let invokeWords: [String]?
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Element, rhs: Element) -> Bool {
        lhs.id == rhs.id
    }
}
