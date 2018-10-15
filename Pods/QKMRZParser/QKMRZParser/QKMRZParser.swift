//
//  QKMRZParser.swift
//  QKMRZParser
//
//  Created by Matej Dorcak on 14/10/2018.
//

import Foundation

public class QKMRZParser {
    let formatter: MRZFieldFormatter
    
    enum MRZFormat: Int {
        case td1, td2, td3, invalid
    }
    
    public init(ocrCorrection: Bool = false) {
        formatter = MRZFieldFormatter(ocrCorrection: ocrCorrection)
    }
    
    // MARK: Parsing
    public func parse(mrzLines: [String]) -> QKMRZResult? {
        let mrzFormat = self.mrzFormat(from: mrzLines)
        
        switch mrzFormat {
        case .td1:
            return TD1(from: mrzLines, using: formatter).result
        case .td2:
            return TD2(from: mrzLines, using: formatter).result
        case .td3:
            return TD3(from: mrzLines, using: formatter).result
        case .invalid:
            return nil
        }
    }
    
    public func parse(mrzString: String) -> QKMRZResult? {
        return parse(mrzLines: mrzString.components(separatedBy: "\n"))
    }
    
    // MARK: MRZ-Format detection
    fileprivate func mrzFormat(from mrzLines: [String]) -> MRZFormat {
        switch mrzLines.count {
        case 2:
            let lineLength = uniformedLineLength(for: mrzLines)
            let possibleFormats = [MRZFormat.td2: TD2.lineLength, .td3: TD3.lineLength]
            
            for (format, requiredLineLength) in possibleFormats where lineLength == requiredLineLength {
                return format
            }
            
            return .invalid
        case 3:
            return (uniformedLineLength(for: mrzLines) == TD1.lineLength) ? .td1 : .invalid
        default:
            return .invalid
        }
    }
    
    fileprivate func uniformedLineLength(for mrzLines: [String]) -> Int? {
        guard let lineLength = mrzLines.first?.count else {
            return nil
        }
        
        if mrzLines.contains(where: { $0.count != lineLength }) {
            return nil
        }
        
        return lineLength
    }
}
