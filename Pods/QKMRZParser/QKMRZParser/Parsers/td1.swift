//
//  td1.swift
//  QKMRZParser
//
//  Created by Matej Dorcak on 14/10/2018.
//

import Foundation

class TD1 {
    static let lineLength = 30
    fileprivate let finalCheckDigit: String
    let documentType: MRZField
    let countryCode: MRZField
    let documentNumber: MRZField
    let optionalData: MRZField
    let birthDate: MRZField
    let sex: MRZField
    let expiryDate: MRZField
    let nationality: MRZField
    let optionalData2: MRZField
    let names: MRZField
    
    fileprivate lazy var allCheckDigitsValid: Bool = {
        let compositedValue = [documentNumber, optionalData, birthDate, expiryDate, optionalData2].reduce("", { ($0 + $1.rawValue + ($1.checkDigit ?? "")) })
        let isCompositedValueValid = MRZField.isValueValid(compositedValue, checkDigit: finalCheckDigit)
        return (documentNumber.isValid! && birthDate.isValid! && expiryDate.isValid! && isCompositedValueValid)
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
            personalNumber: optionalData.value as! String,
            personalNumber2: (optionalData2.value as! String),
            
            isDocumentNumberValid: documentNumber.isValid!,
            isBirthDateValid: birthDate.isValid!,
            isExpiryDateValid: expiryDate.isValid!,
            isPersonalNumberValid: nil,
            allCheckDigitsValid: allCheckDigitsValid
        )
    }()
    
    init(from mrzLines: [String], using formatter: MRZFieldFormatter) {
        let (firstLine, secondLine, thirdLine) = (mrzLines[0], mrzLines[1], mrzLines[2])
        
        documentType = formatter.field(.documentType, from: firstLine, at: 0, length: 2)
        countryCode = formatter.field(.countryCode, from: firstLine, at: 2, length: 3)
        documentNumber = formatter.field(.documentNumber, from: firstLine, at: 5, length: 9, checkDigitFollows: true)
        optionalData = formatter.field(.optionalData, from: firstLine, at: 15, length: 15)
        
        birthDate = formatter.field(.birthDate, from: secondLine, at: 0, length: 6, checkDigitFollows: true)
        sex = formatter.field(.sex, from: secondLine, at: 7, length: 1)
        expiryDate = formatter.field(.expiryDate, from: secondLine, at: 8, length: 6, checkDigitFollows: true)
        nationality = formatter.field(.nationality, from: secondLine, at: 15, length: 3)
        optionalData2 = formatter.field(.optionalData, from: secondLine, at: 18, length: 11)
        finalCheckDigit = formatter.field(.hash, from: secondLine, at: 29, length: 1).rawValue
        
        names = formatter.field(.names, from: thirdLine, at: 0, length: 29)
    }
}
