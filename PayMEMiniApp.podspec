Pod::Spec.new do |spec|
  spec.name         = "PayMEMiniApp"
  spec.version      = "0.1.2"
  spec.summary      = "A short description of PayMEMiniApp."
  spec.description  = <<-DESC
  TODO: Add long description of the pod here.
                   DESC
  spec.homepage     = "https://github.com/PayME-Miniapp/native-ios"
  # spec.screenshots  = "www.example.com/screenshots_1.gif", "www.example.com/screenshots_2.gif"

  # ―――  Spec License  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  spec.license      = { :type => "MIT", :file => "LICENSE" }

  # ――― Author Metadata  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  spec.author             = { "NamPT" => "nampt@payme.vn" }
  # spec.social_media_url   = "https://twitter.com/Phan Thanh Nam"

  # ――― Platform Specifics ――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  spec.platform     = :ios, "13.0"
  spec.swift_versions  = "5.0"
  #  When using multiple platforms
  # spec.ios.deployment_target = "5.0"
  # spec.osx.deployment_target = "10.7"
  # spec.watchos.deployment_target = "2.0"
  # spec.tvos.deployment_target = "9.0"

  # ――― Source Location ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  spec.source       = { :git => "https://github.com/PayME-Miniapp/native-ios.git", :tag => spec.version.to_s }

  # ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
#   spec.source_files  = "Classes", "Classes/**/*.{h,m}"
#   spec.exclude_files = "Classes/Exclude"
  # spec.public_header_files = "Classes/**/*.h"
  spec.vendored_frameworks = "PayMEMiniApp.xcframework"

  # ――― Resources ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  # spec.resource  = "icon.png"
  # spec.resources = "Resources/*.png"
  # spec.preserve_paths = "FilesToSave", "MoreFilesToSave"

  # ――― Project Linking ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  # spec.framework  = "SomeFramework"
  # spec.frameworks = "SomeFramework", "AnotherFramework"
  # spec.library   = "iconv"
  # spec.libraries = "iconv", "xml2"

  # ――― Project Settings ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  spec.dependency 'ZIPFoundation'
  spec.dependency 'GCDWebServer'
  spec.dependency 'SwiftyJSON', '~> 4.0'
  spec.dependency 'NSLogger/Swift'
  spec.dependency 'lottie-ios', '< 4.0'
  spec.dependency 'Mixpanel-swift'
  spec.dependency 'CryptoSwift'
  spec.dependency 'SwiftyRSA'
  spec.user_target_xcconfig = { 'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'YES' }
  # spec.xcconfig = { "HEADER_SEARCH_PATHS" => "$(SDKROOT)/usr/include/libxml2" }
end
