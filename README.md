[![SwiftPackageSupport](https://img.shields.io/badge/Swift_Package_Index-red?logo=swift&logoColor=white)](https://swiftpackageindex.com/Mattijah/QKMRZScanner)
[![Swift 5](https://img.shields.io/badge/Swift-5.0-orange.svg?style=flat)](https://developer.apple.com/swift/)
[![Git](https://img.shields.io/badge/GitHub-Mattijah-blue.svg?style=flat)](https://github.com/Mattijah)


# QKMRZScanner

Scans MRZ (Machine Readable Zone) from identity documents.

![scanning_preview](ReadmeAssets/scanning.gif)

## Installation

##### Swift Package Manager
When adding a package make sure to refer to the `master-spm` branch. The main branch supports CocoaPods only.

##### CocoaPods
Please see [here](https://github.com/Mattijah/QKMRZScanner/tree/master#installation).

## Setup

Assign `QKMRZScannerView` to the component responsible for displaying the camera view.

![storyboard_setup](ReadmeAssets/storyboard.png)


Subsequently connect this component to your UIViewController.

```swift
@IBOutlet weak var mrzScannerView: QKMRZScannerView!
```

#### Start scanning
```swift
override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    mrzScannerView.startScanning()
}
```

#### Stop scanning
```swift
override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    mrzScannerView.stopScanning()
}
```

#### Scanning Result

In order to retrieve the scanning results you need to implement `QKMRZScannerViewDelegate`.

```swift
class MRZScannerViewController: UIViewController, QKMRZScannerViewDelegate {
    @IBOutlet weak var mrzScannerView: QKMRZScannerView!

    override func viewDidLoad() {
        super.viewDidLoad()
        mrzScannerView.delegate = self
    }

    func mrzScannerView(_ mrzScannerView: QKMRZScannerView, didFind scanResult: QKMRZScanResult) {
        print(scanResult)
    }
}
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details
