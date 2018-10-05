//
//  QKCutoutView.swift
//  QKMRZScanner
//
//  Created by S on 05/10/2018.
//

import UIKit

class QKCutoutView: UIView {
    var cutoutRect: CGRect {
        let documentFrameRatio = CGFloat(1.42) // Passport's size (ISO/IEC 7810 ID-3) is 125mm × 88mm
        let (width, height): (CGFloat, CGFloat)
        
        if frame.height > frame.width {
            width = (frame.width * 0.9) // Fill 90% of the width
            height = (width / documentFrameRatio)
        }
        else {
            height = (frame.height * 0.75) // Fill 75% of the height
            width = (height * documentFrameRatio)
        }
        
        let topOffset = (frame.height - height) / 2
        let leftOffset = (frame.width - width) / 2
        
        return CGRect(x: leftOffset, y: topOffset, width: width, height: height)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.black.withAlphaComponent(0.5)
        contentMode = .redraw
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        layer.sublayers?.removeAll()
        
        // Make rectangle cutout
        let maskLayer = CAShapeLayer()
        let path = CGMutablePath()
        let cornerRadius = CGFloat(3)
        
        path.addRoundedRect(in: cutoutRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius)
        path.addRect(bounds)
        
        maskLayer.path = path
        maskLayer.fillRule = kCAFillRuleEvenOdd
        
        layer.mask = maskLayer
        
        // Add border around the cutout
        let borderLayer = CAShapeLayer()
        
        borderLayer.path = UIBezierPath(roundedRect: cutoutRect, cornerRadius: cornerRadius).cgPath
        borderLayer.lineWidth = 3
        borderLayer.strokeColor = UIColor.white.cgColor
        borderLayer.frame = bounds
        
        layer.addSublayer(borderLayer)
    }
}
