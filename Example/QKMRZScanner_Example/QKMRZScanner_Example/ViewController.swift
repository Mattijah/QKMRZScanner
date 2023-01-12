//
//  ViewController.swift
//  QKMRZScanner_Example
//
//  Created by iSeddiqi Apple on 12/01/2023.
//

import UIKit
import QKMRZScanner

class MRZScannerViewController: UIViewController {
    
    @IBOutlet weak var mrzScannerView: QKMRZScannerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        
//        2023-01-12 11:19:13.658966+0400 QKMRZScanner_Example[457:50637] [access] This app has crashed because it attempted to access privacy-sensitive data without a usage description.  The app's Info.plist must contain an NSCameraUsageDescription key with a string value explaining to the user how the app uses this data.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        mrzScannerView.startScanning()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        mrzScannerView.stopScanning()
    }
    
}

extension MRZScannerViewController: QKMRZScannerViewDelegate {
    
    func mrzScannerView(_ mrzScannerView: QKMRZScannerView, didFind scanResult: QKMRZScanResult) {
        print(scanResult)
    }
    
}
