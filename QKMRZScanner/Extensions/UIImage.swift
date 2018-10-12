//
//  UIImage.swift
//  QKMRZScanner
//
//  Created by S on 11/10/2018.
//

import Foundation

extension UIImage {
    // UIImage's cgImage which is used for preprocessing may have
    // wrong orientation. This method fixes that by redrawing the
    // image, respecting UIImage's imageOrientation
    func normalize() -> UIImage {
        if imageOrientation == .up {
            return self
        }
        
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext()!
    }
}
