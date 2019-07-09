//
//  LuminanceThresholdFilter.swift
//  QKMRZScanner
//
//  Created by Matej Dorcak on 09/07/2019.
//

import Foundation

// MARK: - LuminanceThresholdFilter
class LuminanceThresholdFilter: CIFilter {
    @objc var inputImage: CIImage?
    @objc var inputThreshold = 0.5
    
    private static let thresholdKernel = CIColorKernel(source: """
        kernel vec4 thresholdFilter(__sample pixel, float threshold) {
        float luma = dot(pixel.rgb, vec3(0.2126, 0.7152, 0.0722));
        return (luma > threshold) ? vec4(1) : vec4(0, 0, 0, 1);
        }
    """)!
    
    override var attributes: [String: Any] {
        return [
            kCIAttributeFilterDisplayName: String(describing: type(of: self)),
            kCIInputImageKey: [
                kCIAttributeIdentity: 0,
                kCIAttributeClass: "CIImage",
                kCIAttributeDisplayName: "Image",
                kCIAttributeType: kCIAttributeTypeImage
            ],
            #keyPath(inputThreshold): [
                kCIAttributeIdentity: 0,
                kCIAttributeClass: "NSNumber",
                kCIAttributeDefault: 0.5,
                kCIAttributeDisplayName: "Threshold",
                kCIAttributeMin: 0,
                kCIAttributeSliderMin: 0,
                kCIAttributeSliderMax: 1,
                kCIAttributeType: kCIAttributeTypeScalar
            ]
        ]
    }
    
    override var outputImage: CIImage? {
        guard let image = inputImage else {
            return nil
        }
        
        return LuminanceThresholdFilter.thresholdKernel.apply(extent: image.extent, arguments: [image, inputThreshold])
    }
}

// MARK: - FilterVendor
class FilterVendor: CIFilterConstructor {
    static func registerFilters() {
        CIFilter.registerName("LuminanceThresholdFilter", constructor: FilterVendor(), classAttributes: [kCIAttributeFilterCategories: "CustomFilters"])
    }
    
    func filter(withName name: String) -> CIFilter? {
        switch name {
        case "LuminanceThresholdFilter": return LuminanceThresholdFilter()
        default: return nil
        }
    }
}
