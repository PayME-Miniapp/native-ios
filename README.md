# PayME-Miniapp (iOS)

- [Cài đặt](#cài-đặt)
  - [Cài thư viện từ CocoaPods](#cài-thư-viện-từ-cocoapods)
  - [Thiết lập application tương thích với PayMEMiniApp](#thiết-lập-application-tương-thích-với-paymeminiapp)
    - [Info.plist](#infoplist)
    - [Thêm Capabilities](#thêm-capabilities)
    - [Thiết lập cập nhật phiên bản PayMEMiniApp](#thiết-lập-cập-nhật-phiên-bản-paymeminiapp)
  - [Khởi tạo PayMEMiniApp](#khởi-tạo-paymeminiapp)
    - [Thiết lập bộ key từ PayME](#thiết-lập-bộ-key-từ-payme)
    - [Khởi tạo object](#khởi-tạo-object)

# Cài đặt

## Cài thư viện từ CocoaPods

PayME-Miniapp là một dynamic framework (`PayMEMiniApp.xcframework`) được cung cấp thông qua CocoaPods. Để cài đặt vào project, khai báo framework trong Podfile:

```ruby
platform :ios, '13.0'
use_frameworks!

target '<TÊN_TARGET_CỦA_APP>' do
  pod 'PayME-Miniapp', '~> 0.8.0'
end
```

Thêm vào cuối Podfile:

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
    end
  end
end
```

Trường hợp project của bạn không dùng `use_frameworks!`, cần khai báo các pod dưới đây là dynamic framework:

```ruby
$dynamic_framework = [
  'PayME-Miniapp',
  'CryptoSwift',
  'SwiftyRSA',
  'GCDWebServer',
  'NSLogger',
  'lottie-ios',
  'SwiftyJSON',
  'ZIPFoundation',
  'Mixpanel-swift',
  'MixpanelSwiftCommon',
  'jsonlogic',
  'json-enum'
]

pre_install do |installer|
  installer.pod_targets.each do |pod|
    if $dynamic_framework.include?(pod.name)
      def pod.build_type
        Pod::BuildType.dynamic_framework
      end
    end
  end
end
```

Sau khi cập nhật Podfile, chạy lại `pod install`.

## Thiết lập application tương thích với PayMEMiniApp

### Info.plist

Cập nhật Info.plist những key như bên dưới để đảm bảo PayMEMiniApp có thể hoạt động.

![Các key cần thêm vào Info.plist](documents/info_plist.png)

```text
Privacy - Camera Usage Description
Privacy - Face ID Usage Description
Privacy - Photo Library Usage Description
Privacy - Photo Library Additions Usage Description
Privacy - Contacts Usage Description
Privacy - Location When In Use Usage Description
Privacy - Location Always Usage Description
Privacy - NFC Scan Usage Description
ISO7816 application identifiers for NFC Tag Reader Session
```

Tên key gốc (raw key):

```text
NSCameraUsageDescription
NSFaceIDUsageDescription
NSPhotoLibraryUsageDescription
NSPhotoLibraryAddUsageDescription
NSContactsUsageDescription
NSLocationWhenInUseUsageDescription
NSLocationAlwaysUsageDescription
NFCReaderUsageDescription
com.apple.developer.nfc.readersession.iso7816.select-identifiers
```

Hai key NFC dùng cho tính năng eKYC bằng NFC. Ví dụ:

```xml
<key>NFCReaderUsageDescription</key>
<string>Ứng dụng cần dùng NFC để thực hiện eKYC</string>
<key>com.apple.developer.nfc.readersession.iso7816.select-identifiers</key>
<array>
  <string>A0000002471001</string>
  <string>A0000002472001</string>
  <string>00000000000000</string>
</array>
```

### Thêm Capabilities

Ở Xcode, chọn app của bạn ở mục Targets → Signing & Capabilities → nhấn dấu "+" ở góc trên bên phải để mở cửa sổ thêm capability cho app.

![Cửa sổ thêm capability trong Xcode](documents/capabilities.png)

- Tìm và chọn "Near Field Communication Tag Reading" để hỗ trợ eKYC bằng NFC.
- Tìm và chọn "Background Modes", bật lựa chọn "Background Fetch".

![Bật Background Fetch trong Background Modes](documents/background_fetch.png)

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
    let payme = PayME(key: PayMEKey(appId: "<APP_ID>",
                                    publicKey: "-----BEGIN PUBLIC KEY-----<PUBLIC_KEY_BASE64>-----END PUBLIC KEY-----",
                                    privateKey: "-----BEGIN RSA PRIVATE KEY-----<PRIVATE_KEY_BASE64>-----END RSA PRIVATE KEY-----"))
    ```
  ⚠️ Không đưa key thật vào README, source code public hay ảnh chụp màn hình. Dùng bộ key PayME cấp riêng cho ứng dụng của bạn.
