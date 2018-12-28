platform :ios, '10'
source 'https://github.com/CocoaPods/Specs.git'
use_frameworks!

target 'QKMRZScanner' do
    pod 'EVGPUImage2', '~> 0.2.0'
    pod 'QKMRZParser', '~> 1.0.1'
    pod 'SwiftyTesseract', '~> 2.0.1'
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        if target.name == 'SwiftyTesseract'
            target.build_configurations.each do |config|
                config.build_settings['SWIFT_VERSION'] = '4.2'
            end
        end
    end
end
