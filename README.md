# PayMEMiniApp (iOS)
[Cài đặt](#cai-dat)
- [Cài thư viện từ CocoaPods](#cai-thu-vien-tu-cocoapods)
- [Khởi tạo PayMEMiniApp](#khoi-tao-paymeminiapp)

# Cài đặt
## Cài thư viện từ CocoaPods 
PayMEMiniApp là một dynamic framework được cung cấp thông qua CocoaPods. Để cài đặt vào project, thêm khai báo sử dụng framework vào Podfile
```swift
use_framework!

pod PayMEMiniApp
```
Thêm vào cuối Podfile:
```swift
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
    end
  end
end
```

Trường hợp project của bạn không dùng framework, cần thay đổi build config để khai báo framework như sau:
```swift
$dynamic_framework = ['PayMEMiniApp', 'CryptoSwift', 'SwiftyRSA', 'GCDWebServer', 'NSLogger', 'lottie-ios', 'SwiftyJSON', 'ZIPFoundation', 'Mixpanel-swift']
 pre_install do |installer|
   installer.pod_targets.each do |pod|
     if $dynamic_framework.include?(pod.name)
       def pod.build_type;
       Pod::BuildType.dynamic_framework
      end
    end
  end
end
```
## Thiết lập application tương thích với PayMEMiniApp
### Info.plist
Cập nhật Info.plist những key như bên dưới để đảm bảo PayMEMiniApp có thể hoạt động
![img.png](documents/info_plist.png)
```swift
Privacy - Camera Usage Description
Privacy - Face ID Usage Description
Privacy - Photo Library Usage Description
Privacy - Photo Library Additions Usage Description
Privacy - Contacts Usage Description
Privacy - Location When In Use Usage Description
Privacy - Location Always Usage Description
```

Raw Keys version:
```swift
NSCameraUsageDescription
NSFaceIDUsageDescription
NSPhotoLibraryUsageDescription
NSPhotoLibraryAddUsageDescription
NSContactsUsageDescription
NSLocationWhenInUseUsageDescription
NSLocationAlwaysUsageDescription
```
### Thêm Capabilities
Ở XCode, chọn app của bạn ở mục Targets -> Signing & Capabilities -> Nhấn dấu "+" ở góc trên bên phải để mở cửa sổ thêm capability cho app
![img_1.png](documents/capabilities.png)
Tìm và chọn "Background Modes", bật lựa chọn "Background Fetch"
![img.png](documents/background_fetch.png)
### Thiết lập cập nhật phiên bản PayMEMiniApp
Thêm dòng sau vào AppDelegate:
```swift
import UIKit
import PayMEMiniApp

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
...
func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
   completionHandler()
}
...
}
```
## Khởi tạo PayMEMiniApp
### Thiết lập bộ key từ PayME 
Bộ key bao gồm: appId, publicKey, privateKey. Liên hệ PayME để được hướng dẫn.
### Khởi tạo object
- Khởi tạo PayMEKey: là một object chứa bộ key đã được cấp ở bước trên
    ```swift
    PayMEKey(appId: String, publicKey: String, privateKey: String)
    ```
- Khởi tạo PayME: là UIViewController chứa toàn bộ PayMEMiniApp. Việc khởi tạo object này cũng sẽ bắt đầu việc kiểm tra và download phiên bản của PayMEMiniApp, do đó khuyến khích khởi tạo càng sớm càng tốt khi chạy app.
    ```swift
    PayME(key: PayMEKey): UIViewController
    ```
  Ví dụ:
    ```swift
    let payme = PayME(key: PayMEKey(appId: "559163930378",
                                  publicKey: """
                                  -----BEGIN PUBLIC KEY-----
                                  MFwwDQYJKoZIhvcNAQEBBQADSwAwSAJBAK0RONYVPYn/3IWloU83Qy16hKNHhlCx
                                  gTJay6/rERk8tmsMbILLzTYW7H9WOqN2gS0s0ymD+3TxP+q+MxEp0qECAwEAAQ==
                                  -----END PUBLIC KEY-----
                                  """,
                                  privateKey: """
                                  -----BEGIN RSA PRIVATE KEY-----
                                  MIIBOgIBAAJBAMXIuvTT8Z5U/AqyFvBbDApQ2STLm9Ca2nmu2pxqwhrhN+80mOLb
                                  MzbQDRCNpro6S61d34A7cEIX/5gxxrAaVAkCAwEAAQJAfzB70e/uJHTgdHxcNgtG
                                  7edaDMiHFhpPPwtL+GTLGH70yhFDs2eIXFHLY/wfRRcxzwGyGOyvXlGbDjsMFdpn
                                  lQIhAPIoUVsADDfI4KNZEKHaJRVAmz2D0xdiB6R716HA7A0XAiEA0RcPxHzYLhVp
                                  +adoGpJBq7e87BzQrVBJQFSOg8Kim98CIQCYmynyFEye1zwiFR3zMfuOsiFjGfFs
                                  2f2A/f69VEwuTwIgFN/3jAdm0dsDdJBZHWYCtnEmpHAQCW2dkpWekNsKvwMCIGXm
                                  rg+mppNNZQx6+6Swsp8L8Hgc+HikKy02Okijjw0W
                                  -----END RSA PRIVATE KEY-----
                                  """))
    ```

