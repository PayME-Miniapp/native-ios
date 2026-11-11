Pod::Spec.new do |spec|
  spec.name         = 'PayME-Miniapp'
  spec.version      = '0.9.0'
  spec.summary      = 'PayME Miniapp SDK for iOS integration.'
  spec.description  = 'PayME Miniapp SDK for iOS: opens the PayME e-wallet mini-app (payments, deposits, withdrawals, transfers, KYC) inside a partner app.'
  spec.homepage     = 'https://github.com/PayME-Miniapp/native-ios'
  spec.license      = { :type => 'MIT', :file => 'LICENSE' }
  spec.author       = { 'DatTM' => 'dattm@payme.vn' }

  spec.ios.deployment_target = '13.0'
  spec.swift_version = '5.9'
  spec.source       = { :git => 'https://github.com/PayME-Miniapp/native-ios.git', :tag => spec.version.to_s }
  spec.vendored_frameworks = 'PayMEMiniApp.xcframework'

  spec.dependency 'ZIPFoundation', '~> 0.9'
  spec.dependency 'GCDWebServer', '~> 3.0'
  spec.dependency 'SwiftyJSON', '~> 5.0'
  spec.dependency 'NSLogger/Swift'
  spec.dependency 'lottie-ios', '~> 4.6.0'
  spec.dependency 'Mixpanel-swift', '~> 6.0'
  spec.dependency 'CryptoSwift', '~> 1.10.0'
  spec.dependency 'SwiftyRSA'
  spec.dependency 'KalapaEkycSDK', '~> 2.8.0'

  spec.pod_target_xcconfig = { 'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'YES' }
end
