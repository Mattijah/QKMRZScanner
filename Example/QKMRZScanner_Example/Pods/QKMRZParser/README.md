[![Swift 4.0](https://img.shields.io/badge/Swift-4.0-orange.svg?style=flat)](https://developer.apple.com/swift/)
[![Git](https://img.shields.io/badge/GitHub-Mattijah-blue.svg?style=flat)](https://github.com/Mattijah)


# QKMRZParser

Parses MRZ (Machine Readable Zone) from identity documents.

## Supported formats:

* TD1
* TD2
* TD3
* MRV-A
* MRV-B

## Installation

QKMRZParser is available through CocoaPods. To install it, simply add the following line to your Podfile:

```ruby
pod 'QKMRZParser'
```

## Usage

```swift
import QKMRZParser

let mrzLines = [
    "P<UTOERIKSSON<<ANNA<MARIA<<<<<<<<<<<<<<<<<<<",
    "L898902C36UTO7408122F1204159ZE184226B<<<<<10"
]

let mrzParser = QKMRZParser(ocrCorrection: true)
let result = mrzParser.parse(mrzLines: mrzLines)

print(result)
```


## TODO
- [ ] Tests
- [ ] Documentation
- [ ] Support Swiss Driving License
- [ ] Support French national ID
- [ ] Improve OCR correction
- [ ] Latin transliteration
- [ ] Arabic transliteration
- [ ] Cyrillic transliteration



## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details
