//
//  MRZField.swift
//  QKMRZParser
//
//  Created by Matej Dorcak on 14/10/2018.
//

import Foundation

enum MRZFieldType {
    case documentType, countryCode, names, documentNumber, nationality, birthDate, sex, expiryDate, personalNumber, optionalData, hash
}

struct MRZField {
    let value: Any?
    let rawValue: String
    let checkDigit: String?
    let isValid: Bool?
    
    init(value: Any?, rawValue: String, checkDigit: String?) {
        self.value = value
        self.rawValue = rawValue
        self.checkDigit = checkDigit
        self.isValid = (checkDigit == nil) ? nil : MRZField.isValueValid(rawValue, checkDigit: checkDigit!)
    }
    
    // MARK: Static
    static func isValueValid(_ value: String, checkDigit: String) -> Bool {
        guard let numericCheckDigit = Int(checkDigit) else {
            if checkDigit == "<" {
                return value.trimmingFillers().isEmpty
            }
            
            return false
        }
        
        let uppercaseLetters = CharacterSet.uppercaseLetters
        let digits = CharacterSet.decimalDigits
        let weights = [7, 3, 1]
        var total = 0
        
        for (index, character) in value.enumerated() {
            let unicodeScalar = character.unicodeScalars.first!
            let charValue: Int
            
            if uppercaseLetters.contains(unicodeScalar) {
                charValue = Int(10 + unicodeScalar.value) - 65
            }
            else if digits.contains(unicodeScalar) {
                charValue = Int(String(character))!
            }
            else if character == "<" {
                charValue = 0
            }
            else {
                return false
            }
            
            total += (charValue * weights[index % 3])
        }
        
        return (total % 10 == numericCheckDigit)
    }
}
