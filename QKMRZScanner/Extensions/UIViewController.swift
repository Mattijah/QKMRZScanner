//
//  UIViewController.swift
//  QKMRZScanner
//
//  Created by Jasur Bo'kayev on 05/07/21.
//

import Foundation

extension UIViewController {
    
    static var bottomMargin: CGFloat = -1
    static var topMargin: CGFloat = -1
    
    func getBottomMargin() -> CGFloat{
        if UIViewController.bottomMargin > 0{
            return UIViewController.bottomMargin
        }
        
        if #available(iOS 11.0, *) {
            let window = UIApplication.shared.keyWindow
            if let bottomPadding = window?.safeAreaInsets.bottom{
                return bottomPadding
            }
        }
        
        return 0
    }
    
    func getTopMargin() -> CGFloat {
        if UIViewController.topMargin > 0 {
            return UIViewController.topMargin
        }
        
        if #available(iOS 11.0, *) {
            let window = UIApplication.shared.keyWindow
            if let topPadding = window?.safeAreaInsets.top {
                return topPadding
            }
        }
        
        return 0
    }
    
}
