[![Swift 4.2](https://img.shields.io/badge/Swift-4.2-orange.svg?style=flat)](https://developer.apple.com/swift/)
[![Git](https://img.shields.io/badge/GitHub-Mattijah-blue.svg?style=flat)](https://github.com/Mattijah)


# QKMRZScanner

Scans MRZ (Machine Readable Zone) from identity documents.

![scanning_preview](ReadmeAssets/scanning.gif)

## Installation

QKMRZScanner is available through CocoaPods. To install it, simply add the following line to your Podfile:

```ruby
pod 'QKMRZScanner'
```

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
