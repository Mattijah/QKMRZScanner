//
//  AVCaptureVideoOrientation.swift
//  QKMRZScanner
//
//  Created by Matej Dorcak on 05/10/2018.
//

import Foundation
import AVFoundation

extension AVCaptureVideoOrientation {
    internal init(orientation: UIInterfaceOrientation) {
        switch orientation {
        case .portrait:
            self = .portrait
        case .portraitUpsideDown:
            self = .portraitUpsideDown
        case .landscapeLeft:
            self = .landscapeLeft
        case .landscapeRight:
            self = .landscapeRight
        default:
            self = .portrait
        }
    }
}
