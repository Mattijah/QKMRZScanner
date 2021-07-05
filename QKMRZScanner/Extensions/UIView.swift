//
//  UIView.swift
//  QKMRZScanner
//
//  Created by Jasur Bo'kayev on 05/07/21.
//

import Foundation

extension UIView {
    
    func getBottomMargin() -> CGFloat{
        if #available(iOS 11.0, *) {
            let window = UIApplication.shared.keyWindow
            if let bottomPadding = window?.safeAreaInsets.bottom{
                return bottomPadding
            }
        }
        
        return 0
    }
    
    func getTopMargin() -> CGFloat {
        if #available(iOS 11.0, *) {
            let window = UIApplication.shared.keyWindow
            if let topPadding = window?.safeAreaInsets.top {
                return topPadding
            }
        }
        
        return 0
    }
    
}
