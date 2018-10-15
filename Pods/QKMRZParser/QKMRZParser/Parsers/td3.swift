//
//  td3.swift
//  QKMRZParser
//
//  Created by Matej Dorcak on 14/10/2018.
//

import Foundation

class TD3 {
    static let lineLength = 44
    fileprivate let finalCheckDigit: String?
    let documentType: MRZField
    let countryCode: MRZField
    let names: MRZField
    let documentNumber: MRZField
    let nationality: MRZField
    let birthDate: MRZField
    let sex: MRZField
    let expiryDate: MRZField
    let personalNumber: MRZField
    
    fileprivate lazy var allCheckDigitsValid: Bool = {
        if let checkDigit = finalCheckDigit {
            let compositedValue = [documentNumber, birthDate, expiryDate, personalNumber].reduce("", { ($0 + $1.rawValue + $1.checkDigit!) })
            let isCompositedValueValid = MRZField.isValueValid(compositedValue, checkDigit: checkDigit)
            return (documentNumber.isValid! && birthDate.isValid! && expiryDate.isValid! && personalNumber.isValid! && isCompositedValueValid)
        }
        else {
            return (documentNumber.isValid! && birthDate.isValid! && expiryDate.isValid!)
        }
    }()
    
    lazy var result: QKMRZResult = {
        let (surnames, givenNames) = names.value as! (String, String)
        
        return QKMRZResult(
            documentType: documentType.value as! String,
            countryCode: countryCode.value as! String,
            surnames: surnames,
            givenNames: givenNames,
            documentNumber: documentNumber.value as! String,
            nationality: nationality.value as! String,
            birthDate: birthDate.value as! Date?,
            sex: sex.value as! String?,
            expiryDate: expiryDate.value as! Date?,
            personalNumber: personalNumber.value as! String,
            personalNumber2: nil,
            
            isDocumentNumberValid: documentNumber.isValid!,
            isBirthDateValid: birthDate.isValid!,
            isExpiryDateValid: expiryDate.isValid!,
            isPersonalNumberValid: personalNumber.isValid,
            allCheckDigitsValid: allCheckDigitsValid
        )
    }()
    
    init(from mrzLines: [String], using formatter: MRZFieldFormatter) {
        let (firstLine, secondLine) = (mrzLines[0], mrzLines[1])
        let isVisaDocument = (firstLine.substring(0, to: 0) == "V") // MRV-A type
        
        documentType = formatter.field(.documentType, from: firstLine, at: 0, length: 2)
        countryCode = formatter.field(.countryCode, from: firstLine, at: 2, length: 3)
        names = formatter.field(.names, from: firstLine, at: 5, length: 39)
        
        documentNumber = formatter.field(.documentNumber, from: secondLine, at: 0, length: 9, checkDigitFollows: true)
        nationality = formatter.field(.nationality, from: secondLine, at: 10, length: 3)
        birthDate = formatter.field(.birthDate, from: secondLine, at: 13, length: 6, checkDigitFollows: true)
        sex = formatter.field(.sex, from: secondLine, at: 20, length: 1)
        expiryDate = formatter.field(.expiryDate, from: secondLine, at: 21, length: 6, checkDigitFollows: true)
        
        if isVisaDocument {
            personalNumber = formatter.field(.optionalData, from: secondLine, at: 28, length: 16)
            finalCheckDigit = nil
        }
        else {
            personalNumber = formatter.field(.personalNumber, from: secondLine, at: 28, length: 14, checkDigitFollows: true)
            finalCheckDigit = formatter.field(.hash, from: secondLine, at: 43, length: 1).rawValue
        }
    }
}
