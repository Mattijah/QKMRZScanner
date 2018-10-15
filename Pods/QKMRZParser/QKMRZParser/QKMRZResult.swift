//
//  QKMRZResult.swift
//  QKMRZParser
//
//  Created by Matej Dorcak on 14/10/2018.
//

import Foundation

public struct QKMRZResult {
    public let documentType: String
    public let countryCode: String
    public let surnames: String
    public let givenNames: String
    public let documentNumber: String
    public let nationality: String
    public let birthDate: Date? // `nil` if formatting failed
    public let sex: String? // `nil` if formatting failed
    public let expiryDate: Date? // `nil` if formatting failed
    public let personalNumber: String
    public let personalNumber2: String? // `nil` if not provided
    
    public let isDocumentNumberValid: Bool
    public let isBirthDateValid: Bool
    public let isExpiryDateValid: Bool
    public let isPersonalNumberValid: Bool?
    public let allCheckDigitsValid: Bool
}
