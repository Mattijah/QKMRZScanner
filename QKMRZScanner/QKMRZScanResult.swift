//
//  QKMRZScanResult.swift
//  QKMRZScanner
//
//  Created by Matej Dorcak on 16/10/2018.
//

import Foundation
import QKMRZParser

public class QKMRZScanResult {
    public let documentImage: UIImage
    public let documentType: String
    public let countryCode: String
    public let surnames: String
    public let givenNames: String
    public let documentNumber: String
    public let nationality: String
    public let birthDate: Date?
    public let sex: String?
    public let expiryDate: Date?
    public let personalNumber: String
    public let personalNumber2: String?
    
    public lazy fileprivate(set) var faceImage: UIImage? = {
        guard let documentImage = CIImage(image: documentImage) else {
            return nil
        }
        
        let faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: CIContext.shared, options: [CIDetectorAccuracy: CIDetectorAccuracyLow])!
        
        guard let face = faceDetector.features(in: documentImage).first else {
            return nil
        }
        
        let increasedFaceBounds = face.bounds.insetBy(dx: -30, dy: -85).offsetBy(dx: 0, dy: 50)
        let faceImage = documentImage.cropped(to: increasedFaceBounds)
        
        guard let cgImage = CIContext.shared.createCGImage(faceImage, from: faceImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }()
    
    init(mrzResult: QKMRZResult, documentImage image: UIImage) {
        documentImage = image
        documentType = mrzResult.documentType
        countryCode = mrzResult.countryCode
        surnames = mrzResult.surnames
        givenNames = mrzResult.givenNames
        documentNumber = mrzResult.documentNumber
        nationality = mrzResult.nationality
        birthDate = mrzResult.birthDate
        sex = mrzResult.sex
        expiryDate = mrzResult.expiryDate
        personalNumber = mrzResult.personalNumber
        personalNumber2 = mrzResult.personalNumber2
    }
}
