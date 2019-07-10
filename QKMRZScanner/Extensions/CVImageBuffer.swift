//
//  CVImageBuffer.swift
//  QKMRZScanner
//
//  Created by Matej Dorcak on 10/07/2019.
//

import Foundation

extension CVImageBuffer {
    var cgImage: CGImage? {
        CVPixelBufferLockBaseAddress(self, .readOnly)
        
        let baseAddress = CVPixelBufferGetBaseAddress(self)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(self)
        let (width, height) = (CVPixelBufferGetWidth(self), CVPixelBufferGetHeight(self))
        let bitmapInfo = CGBitmapInfo(rawValue: (CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue))
        let context = CGContext.init(data: baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: bitmapInfo.rawValue)
        
        guard let cgImage = context?.makeImage() else {
            return nil
        }
        
        CVPixelBufferUnlockBaseAddress(self, .readOnly)
        
        return cgImage
    }
}
