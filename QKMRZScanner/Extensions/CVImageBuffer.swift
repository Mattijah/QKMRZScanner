//
//  CVImageBuffer.swift
//  QKMRZScanner
//
//  Created by Matej Dorcak on 10/07/2019.
//

import Foundation
import CoreVideo
import CoreImage

extension CVImageBuffer {
    var cgImage: CGImage? {
        let ciImage = CIImage(cvPixelBuffer: self)
        let cgImage = CIContext.shared.createCGImage(ciImage, from: ciImage.extent)
        return cgImage
    }
}
