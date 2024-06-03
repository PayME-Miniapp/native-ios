Pod::Spec.new do |spec|
  spec.name         = "PayME-Miniapp"
  spec.version      = "0.2.49"
  spec.summary      = "A short description of PayMEMiniApp."
  spec.description  = <<-DESC
  TODO: Add long description of the pod here.
                   DESC
  spec.homepage     = "https://github.com/PayME-Miniapp/native-ios"

  # ―――  Spec License  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  spec.license      = { :type => "MIT", :file => "LICENSE" }

  # ――― Author Metadata  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  spec.author             = { "DatTM" => "dattm@payme.vn" }

  # ――― Platform Specifics ――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  spec.swift_versions  = "5.0"

  #  When using multiple platforms
  spec.ios.deployment_target = '12.0'

  # ――― Source Location ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  spec.source       = { :git => "https://github.com/PayME-Miniapp/native-ios.git", :tag => spec.version.to_s }

  # ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  spec.vendored_frameworks = "PayMEMiniApp.xcframework"

  # ――― Project Settings ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  spec.dependency 'ZIPFoundation', '~> 0.9'
  spec.dependency 'GCDWebServer', '~> 3.0'
  spec.dependency 'SwiftyJSON', '~> 4.0'
  spec.dependency 'NSLogger/Swift'
  spec.dependency 'lottie-ios', '4.4.1'
  spec.dependency 'Mixpanel-swift', '~> 4.0'
  spec.dependency 'CryptoSwift', '~> 1.8.0'
  spec.dependency 'SwiftyRSA'

  spec.pod_target_xcconfig = { 'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'YES' }
end
