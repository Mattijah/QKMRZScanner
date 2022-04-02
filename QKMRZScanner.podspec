Pod::Spec.new do |s|
  s.name     = "QKMRZScanner"
  s.version  = "2.2.1"
  s.platform = :ios, "13"
  s.ios.deployment_target = "11.0"
  s.swift_version = "5.0"
  s.pod_target_xcconfig = { "EXCLUDED_ARCHS[sdk=iphonesimulator*]" => "arm64" }
  
  s.summary  = "Scans MRZ (Machine Readable Zone) from identity documents (passport, id, visa)."
  s.author   = { "Matej Dorcak" => "sss.mado@gmail.com" }
  s.homepage = "https://github.com/Mattijah/QKMRZScanner"
  s.license  = { :type => "MIT", :file => "LICENSE" }

  s.source   = { :git => "https://github.com/Mattijah/QKMRZScanner.git", :tag => "v#{s.version}" }
  s.source_files = "QKMRZScanner/**/*.{swift}"
  s.resources    = "QKMRZScanner/Supporting Files/tessdata"
  s.frameworks   =  "Foundation", "UIKit", "AVFoundation", "CoreImage", "AudioToolbox"
  
  s.dependency "QKMRZParser", "~> 2.0.0"
  s.dependency "SwiftyTesseract", "~> 3.1.3"
end
