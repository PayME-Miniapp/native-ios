Pod::Spec.new do |spec|
  spec.name         = "PayME-Miniapp"
  spec.version      = "0.2.50"
  spec.summary      = "A short description of PayMEMiniApp."
  spec.description  = "TODO: Add long description of the pod here."
  spec.homepage     = "https://github.com/PayME-Miniapp/native-ios"
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author       = { "DatTM" => "dattm@payme.vn" }

  spec.swift_versions  = "5.0"
  spec.ios.deployment_target = '13.0'

  spec.source       = { :git => "https://github.com/PayME-Miniapp/native-ios.git", :tag => spec.version.to_s }
  spec.vendored_frameworks = "PayMEMiniApp.xcframework"

  spec.dependencies = [
    "ZIPFoundation", "~> 0.9",
    "GCDWebServer", "~> 3.0",
    "SwiftyJSON", "~> 4.0",
    "NSLogger/Swift",
    "lottie-ios",
    "Mixpanel-swift", "~> 4.0",
    "CryptoSwift", "~> 1.8.0",
    "SwiftyRSA"
  ]

  spec.pod_target_xcconfig = { 'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'YES' }
end