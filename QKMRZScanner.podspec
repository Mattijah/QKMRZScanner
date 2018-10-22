Pod::Spec.new do |s|
  s.name     = 'QKMRZScanner'
  s.version  = '1.0.0'
  s.platform = :ios, '10'
  s.swift_version = '4.0'

  s.summary  = 'Scans MRZ from identity documents.'
  s.author   = { 'Matej Dorcak' => 'sss.mado@gmail.com' }
  s.homepage = 'https://www.quko.app'
  s.license  = ''

  s.source   = { :git => '.', :tag => "v#{s.version}" }
  s.source_files = 'QKMRZScanner/**/*.{swift}'
  s.resources    = 'QKMRZScanner/Supporting Files/tessdata'
  s.frameworks   =  'Foundation', 'UIKit', 'AVFoundation', 'CoreImage', 'AudioToolbox', 'TesseractOCR'
  
  s.dependency 'QKGPUImage2'
  s.dependency 'QKMRZParser'
  s.dependency 'TesseractOCRiOS'
end
