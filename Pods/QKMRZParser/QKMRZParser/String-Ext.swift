//
//  String-Ext.swift
//  QKMRZParser
//
//  Created by Matej Dorcak on 14/10/2018.
//

import Foundation

// MARK: Parser related
extension String {
    func trimmingFillers() -> String {
        return trimmingCharacters(in: CharacterSet(charactersIn: "<"))
    }
}

// MARK: Generic
extension String {
    func replace(_ target: String, with: String) -> String {
        return replacingOccurrences(of: target, with: with, options: .literal, range: nil)
    }
    
    func substring(_ from: Int, to: Int) -> String {
        let fromIndex = index(startIndex, offsetBy: from)
        let toIndex = index(startIndex, offsetBy: to + 1)
        return String(self[fromIndex..<toIndex])
    }
}
