Pod::Spec.new do |s|
  s.name     = "QKMRZScanner"
  s.version  = "1.1.1"
  s.platform = :ios, "10"
  s.swift_version = "4.2"

  s.summary  = "Scans MRZ (Machine Readable Zone) from identity documents."
  s.author   = { "Matej Dorcak" => "sss.mado@gmail.com" }
  s.homepage = "https://github.com/Mattijah/QKMRZScanner"
  s.license  = { :type => "MIT", :file => "LICENSE" }

  s.source   = { :git => "https://github.com/Mattijah/QKMRZScanner.git", :tag => "v#{s.version}" }
  s.source_files = "QKMRZScanner/**/*.{swift}"
  s.resources    = "QKMRZScanner/Supporting Files/tessdata"
  s.frameworks   =  "Foundation", "UIKit", "AVFoundation", "CoreImage", "AudioToolbox"
  
  s.dependency "EVGPUImage2"
  s.dependency "QKMRZParser"
  s.dependency "SwiftyTesseract"
end
