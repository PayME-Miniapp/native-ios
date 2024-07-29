Pod::Spec.new do |spec|
  spec.name         = 'PayME-Miniapp'
  spec.version      = '0.4.6'
  spec.summary      = 'A short description of PayMEMiniApp.'
  spec.description  = 'TODO: Add long description of the pod here.'
  spec.homepage     = 'https://github.com/PayME-Miniapp/native-ios'
  spec.license      = { :type => 'MIT', :file => 'LICENSE' }
  spec.author       = { 'DatTM' => 'dattm@payme.vn' }

  spec.swift_versions  = '5.0'
  spec.ios.deployment_target = '13.0'

  spec.source       = { :git => 'https://github.com/PayME-Miniapp/native-ios.git', :tag => spec.version.to_s }
  spec.vendored_frameworks = 'PayMEMiniApp.xcframework', 'KalapaSDK.xcframework'

  spec.dependency 'ZIPFoundation', '~> 0.9'
  spec.dependency 'GCDWebServer', '~> 3.0'
  spec.dependency 'SwiftyJSON', '~> 4.0'
  spec.dependency 'NSLogger/Swift'
  spec.dependency 'lottie-ios', '~> 4.4.0'
  spec.dependency 'Mixpanel-swift', '~> 4.0'
  spec.dependency 'CryptoSwift', '~> 1.8.0'
  spec.dependency 'SwiftyRSA'

  spec.pod_target_xcconfig = { 'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'YES' }
end