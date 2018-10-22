platform :ios, '10'
source 'https://github.com/CocoaPods/Specs.git'
use_frameworks!

target 'QKMRZScanner' do
    pod 'QKGPUImage2', :podspec => './QKGPUImage2.podspec'
    pod 'QKMRZParser', '~> 1.0.1'
    pod 'TesseractOCRiOS', '~> 4.0.0'
end

#TesseractOCR requires disabled bitcode
post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['ENABLE_BITCODE'] = 'NO'
        end
    end
end
