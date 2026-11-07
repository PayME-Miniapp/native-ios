**Tiếng Việt** | [English](README.en.md)

# PayME Miniapp iOS SDK

SDK nhúng PayME Miniapp (ví, thanh toán, nạp/rút/chuyển tiền, eKYC, thanh toán dịch vụ) vào ứng dụng iOS của đối tác.

Phiên bản hiện tại: pod `PayME-Miniapp` **0.8.3** (SDK 1.0.24, mini-app patch 0502). Xem [lịch sử phiên bản](#lịch-sử-phiên-bản-và-hỗ-trợ).

> `0.8.0`–`0.8.2` có cùng API với `0.8.3`; nên dùng `0.8.3`. Tag `0.8.2` có trên GitHub nhưng không được phát hành lên CocoaPods trunk.

> Từ 0.8.0, SDK nhận `identityToken` thay cho số điện thoại. Đây là thay đổi không tương thích với 0.7.x. Xem [Nâng cấp từ 0.7.x](#nâng-cấp-từ-07x).

## Mục lục

- [Yêu cầu](#yêu-cầu)
- [Cài đặt](#cài-đặt)
- [Cấu hình ứng dụng](#cấu-hình-ứng-dụng)
  - [Info.plist](#infoplist)
  - [Capabilities](#capabilities)
- [Bắt đầu nhanh](#bắt-đầu-nhanh)
- [identityToken](#identitytoken)
- [Tham chiếu API](#tham-chiếu-api)
  - [Khởi tạo PayME](#khởi-tạo-payme)
  - [PayMEConfig](#paymeconfig)
  - [Mở mini-app](#mở-mini-app)
  - [Các action](#các-action)
  - [Tham số dữ liệu](#tham-số-dữ-liệu)
  - [getBalance](#getbalance)
  - [getAccountInformation](#getaccountinformation)
  - [setLanguage](#setlanguage)
  - [close](#close)
  - [PayMEDelegate](#paymedelegate)
- [Mã lỗi](#mã-lỗi)
- [Nâng cấp từ 0.7.x](#nâng-cấp-từ-07x)
- [Cập nhật OTA](#cập-nhật-ota)
- [Lịch sử phiên bản và hỗ trợ](#lịch-sử-phiên-bản-và-hỗ-trợ)

## Yêu cầu

| Thành phần | Phiên bản |
| --- | --- |
| iOS (deployment target) | 13.0 trở lên |
| Xcode | 26.2 trở lên |
| Swift | Trình biên dịch Swift 6.2.3 trở lên (đi kèm Xcode 26.2). Framework được build bằng Swift 6.2.3 nên Xcode cũ hơn không đọc được. |
| CocoaPods | Khuyến nghị 1.17.0 trở lên (bản dùng để phát hành SDK) |

SDK là dynamic framework (`PayMEMiniApp.xcframework`), phân phối qua CocoaPods.

## Cài đặt

Khai báo pod trong `Podfile`:

```ruby
platform :ios, '13.0'
use_frameworks!

target 'YourApp' do
  pod 'PayME-Miniapp', '0.8.3'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      # Framework được build với library evolution: các pod phụ thuộc cũng phải bật.
      config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
      # Một số pod phụ thuộc (ví dụ NSLogger) khai báo iOS thấp hơn 13.0, gây lỗi libarclite trên Xcode mới.
      deployment_target = config.build_settings['IPHONEOS_DEPLOYMENT_TARGET']
      if Gem::Version.new(deployment_target || '0') < Gem::Version.new('13.0')
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
      end
    end
  end
end
```

Sau đó chạy:

```sh
pod install
```

Nếu `Podfile` đã có `post_install`, gộp nội dung trên vào khối hiện có.

Có thể cài trực tiếp theo tag git thay cho CocoaPods trunk:

```ruby
pod 'PayME-Miniapp', :git => 'https://github.com/PayME-Miniapp/native-ios.git', :tag => '0.8.3'
```

**Khi nâng cấp phiên bản:**

- Cài từ trunk: chạy `pod repo update` (hoặc `pod install --repo-update`) để CocoaPods thấy bản mới.
- Cài theo tag git, hoặc đã từng cài 0.8.0: xoá cache rồi cài lại.

  ```sh
  pod cache clean PayME-Miniapp --all
  pod install
  ```

**Dự án không dùng `use_frameworks!`:** khai báo các pod sau là dynamic framework.

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

## Cấu hình ứng dụng

### Info.plist

Thêm các key sau. Mỗi chuỗi mô tả hiển thị trong hộp thoại xin quyền của iOS, nên viết rõ mục đích.

![Các key cần thêm vào Info.plist](documents/info_plist.png)

| Key | Tên hiển thị trong Xcode | Mục đích |
| --- | --- | --- |
| `NSCameraUsageDescription` | Privacy - Camera Usage Description | Chụp giấy tờ và khuôn mặt khi eKYC, xác thực khuôn mặt, quét mã QR |
| `NSFaceIDUsageDescription` | Privacy - Face ID Usage Description | Xác thực bằng Face ID thay cho PIN |
| `NSPhotoLibraryUsageDescription` | Privacy - Photo Library Usage Description | Chọn ảnh từ thư viện (ví dụ ảnh mã QR) |
| `NSPhotoLibraryAddUsageDescription` | Privacy - Photo Library Additions Usage Description | Lưu ảnh mã QR vào thư viện |
| `NSContactsUsageDescription` | Privacy - Contacts Usage Description | Chọn số điện thoại từ danh bạ khi chuyển tiền, nạp điện thoại |
| `NFCReaderUsageDescription` | Privacy - NFC Scan Usage Description | Đọc chip CCCD khi eKYC bằng NFC |
| `com.apple.developer.nfc.readersession.iso7816.select-identifiers` | ISO7816 application identifiers for NFC Tag Reader Session | Danh sách AID của chip CCCD |

Ví dụ:

```xml
<key>NSCameraUsageDescription</key>
<string>Ứng dụng cần dùng camera để xác thực danh tính và quét mã QR</string>
<key>NSFaceIDUsageDescription</key>
<string>Ứng dụng dùng Face ID để xác thực giao dịch</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Ứng dụng cần truy cập thư viện ảnh để chọn ảnh mã QR</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>Ứng dụng cần lưu ảnh mã QR vào thư viện ảnh</string>
<key>NSContactsUsageDescription</key>
<string>Ứng dụng cần truy cập danh bạ để chọn số điện thoại</string>
<key>NFCReaderUsageDescription</key>
<string>Ứng dụng cần dùng NFC để đọc chip căn cước công dân</string>
<key>com.apple.developer.nfc.readersession.iso7816.select-identifiers</key>
<array>
  <string>A0000002471001</string>
  <string>A0000002472001</string>
  <string>00000000000000</string>
</array>
```

**Mở app ngân hàng (tuỳ chọn).** Mini-app có thể mở app ngân hàng bằng deeplink trong một số luồng thanh toán. iOS chỉ cho mở các scheme đã khai báo trong `LSApplicationQueriesSchemes`. Liên hệ PayME để nhận danh sách scheme cần khai báo, ví dụ:

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
  <string>vcbpartner</string>
  <string>bidv.smartbanking.partner</string>
</array>
```

### Capabilities

Trong Xcode, chọn target của app → **Signing & Capabilities** → nhấn **+ Capability**.

![Cửa sổ thêm capability trong Xcode](documents/capabilities.png)

- Thêm **Near Field Communication Tag Reading** để hỗ trợ eKYC bằng NFC. Xcode sẽ thêm entitlement `com.apple.developer.nfc.readersession.formats` với giá trị `TAG`.

SDK không cần **Background Modes** (Background Fetch) và không cần xử lý `application(_:handleEventsForBackgroundURLSession:completionHandler:)`. Bản cập nhật mini-app được tải trong lúc mở, không tải nền.

## Bắt đầu nhanh

```swift
import UIKit
import PayMEMiniApp

final class WalletViewController: UIViewController, PayMEDelegate {
  private var payme: PayME!

  override func viewDidLoad() {
    super.viewDidLoad()
    payme = PayME(
      key: PayMEKey(
        appId: "YOUR_APP_ID",
        publicKey: "-----BEGIN PUBLIC KEY-----...-----END PUBLIC KEY-----",
        privateKey: "-----BEGIN RSA PRIVATE KEY-----...-----END RSA PRIVATE KEY-----"),
      locale: .vi)
    payme.delegate = self
  }

  // identityToken do server của bạn lấy từ PayME, xem mục identityToken.
  func openWallet(identityToken: String) {
    payme.open(with: .open(identityToken: identityToken), from: self, type: .screen)
  }

  func onResponse(action: PayMEAction, response: [String: Any]) { /* xử lý kết quả */ }
  func onError(action: PayMEAction, error: PayMEError) { /* xem mục Mã lỗi */ }
}
```

Bộ key (`appId`, `publicKey`, `privateKey`) do PayME cấp riêng cho ứng dụng của bạn. Không đưa key thật vào source code public, README hay ảnh chụp màn hình.

## identityToken

`identityToken` là chuỗi do PayME BE ký cho một người dùng của đối tác. SDK dùng chuỗi này để định danh người dùng, thay cho số điện thoại ở 0.7.x.

**Luồng lấy token:**

1. App gọi API của server đối tác để xin token cho người dùng đang đăng nhập.
2. Server đối tác gọi API `identityToken/init` của PayME BE (server tới server) với thông tin người dùng. Liên hệ PayME để nhận tài liệu API này.
3. Server trả token về app. App truyền token vào SDK (`open`, `getBalance`, `getAccountInformation`).

```
App đối tác ──(1)──▶ Server đối tác ──(2) identityToken/init──▶ PayME BE
     ▲                      │
     └───────(3) token ─────┘
App đối tác ──▶ PayME SDK (open / getBalance / getAccountInformation)
```

**Thời hạn:** token có hiệu lực 15 phút và dùng lại được nhiều lần trong thời hạn đó. Hết hạn thì lấy token mới từ server.

**Action nào cần token:**

| Trường hợp | identityToken |
| --- | --- |
| Mọi action trừ `PAYMENT` và `PAYME`, cùng `getBalance`, `getAccountInformation` | Bắt buộc |
| `PAYMENT` (`.payment`) | Tuỳ chọn. Có token: thanh toán được bằng ví PayME. Không có: người dùng thanh toán như khách vãng lai (thẻ, QR). |
| `PAYME` (`.payme()`) | Không dùng. Người dùng tự nhập số điện thoại và đăng nhập bằng PIN. |

**Lỗi liên quan:**

- Token rỗng (hoặc chỉ có khoảng trắng): SDK trả `onError` với code `IDENTITY_TOKEN_REQUIRED`, không gọi mạng và không mở mini-app.
- Token sai hoặc hết hạn: mini-app tự đóng và trả `onError` với code `401`. `getBalance` và `getAccountInformation` cũng trả `401`. Lấy token mới rồi gọi lại.

**Bảo mật:**

- Chỉ server đối tác được gọi `identityToken/init`. Không gọi API này từ app và không nhúng thông tin xác thực của API vào app.
- Chỉ giữ token trong bộ nhớ. Không ghi log, không lưu (UserDefaults, Keychain, file) và không đưa vào URL.
- Lấy token ngay trước khi mở mini-app, không lấy sẵn từ lâu.
- SDK không lưu token, xoá token khỏi bộ nhớ khi mini-app đóng và che token trong log.

## Tham chiếu API

Mọi API của `PayME` chạy trên main thread. Các callback của `PayMEDelegate` cũng được gọi trên main thread.

### Khởi tạo PayME

```swift
public init(key: PayMEKey, locale: Locale? = .vi)
```

| Tham số | Kiểu | Bắt buộc | Ý nghĩa |
| --- | --- | --- | --- |
| `key` | `PayMEKey` | Có | Bộ key PayME cấp: `PayMEKey(appId:publicKey:privateKey:)` |
| `locale` | `Locale?` (`PayMEMiniApp.Locale`) | Không | Ngôn ngữ hiển thị: `.vi` (mặc định) hoặc `.en` |

| Trường của `PayMEKey` | Kiểu | Ý nghĩa |
| --- | --- | --- |
| `appId` | `String` | Mã ứng dụng do PayME cấp |
| `publicKey` | `String` | Public key RSA của PayME, định dạng PEM (`-----BEGIN PUBLIC KEY-----...`) |
| `privateKey` | `String` | Private key RSA của ứng dụng, định dạng PEM như PayME cấp (`-----BEGIN RSA PRIVATE KEY-----...`) |

`PayME` là một `UIViewController`. Bạn không cần tự hiển thị nó: SDK tự present khi cần (ví dụ màn tải bản cập nhật). Giữ đối tượng `PayME` trong suốt thời gian dùng mini-app (ví dụ thuộc tính của view controller hoặc một service dùng chung).

Lưu ý:

- `PayMEMiniApp` khai báo enum `Locale` và `Environment` trùng tên với `Foundation.Locale` và `SwiftUI.Environment`. Dùng dạng rút gọn (`.vi`, `.sbx`) hoặc ghi đầy đủ `PayMEMiniApp.Locale`.
- `delegate` và `walletDelegate` là tham chiếu mạnh (strong). Nếu object làm delegate cũng giữ `PayME` (ví dụ view controller vừa giữ `payme` vừa là delegate) thì tạo vòng tham chiếu: dùng một object trung gian không giữ `PayME`, hoặc gán `payme.delegate = nil` khi không dùng nữa.

### PayMEConfig

Cấu hình dùng chung, truy cập qua `PayMEConfig.instance`. Đặt trước khi gọi `open`, `getBalance` hoặc `getAccountInformation`.

| Thuộc tính / hàm | Kiểu | Mặc định | Ý nghĩa |
| --- | --- | --- | --- |
| `env` | `Environment` | `.prod` | Môi trường PayME: `.prod` (production) hoặc `.sbx` (sandbox) |
| `setMode(_:)` | `String` | `"miniapp_product"` | Kênh cập nhật mini-app. Khi chạy sandbox, dùng `"miniapp_sandbox"`. Chỉ đổi theo hướng dẫn của PayME. |
| `locale` / `setLanguage(_:)` | `Locale` | `.vi` | Ngôn ngữ hiển thị |
| `theme` | `Theme` | Màu PayME | Màu các màn camera eKYC native: `Theme(primary:background:textPrimary:)` |
| `setDebugMode(_:)` | `Bool` | `false` | Bật log debug của SDK. Chỉ dùng khi phát triển, tắt ở bản phát hành. |

Ví dụ chạy sandbox:

```swift
PayMEConfig.instance.env = .sbx
PayMEConfig.instance.setMode("miniapp_sandbox")
```

### Mở mini-app

```swift
public func open(
  with openData: PayMEOpeningParam,
  from currentVC: UIViewController? = nil,
  type: PayMEOpeningType? = .screen
)
```

| Tham số | Kiểu | Bắt buộc | Ý nghĩa |
| --- | --- | --- | --- |
| `openData` | `PayMEOpeningParam` | Có | Action cần mở, tạo bằng các factory ở mục [Các action](#các-action) |
| `currentVC` | `UIViewController?` | Có (thực tế) | View controller đang hiển thị. SDK present mini-app từ view controller này. Truyền `nil` chỉ khi `PayME` đã nằm trong một `UINavigationController`: SDK push mini-app vào navigation đó (bỏ qua `type`). Không có cả hai thì `onError` trả `MINIAPP_CANNOT_PRESENT`. |
| `type` | `PayMEOpeningType?` | Không | `.screen` (toàn màn hình, mặc định) hoặc `.modal` (bottom sheet; iOS 15 trở lên có thể kéo giãn) |

Kết quả trả về qua [`PayMEDelegate`](#paymedelegate).

#### Mở, đóng và kết quả đóng

- **Mỗi lúc chỉ một mini-app.** Gọi `open` khi đang có mini-app mở, hoặc một lần `open` khác chưa xong (đang kiểm tra/tải bản cập nhật), trả `onError` với `MINIAPP_ALREADY_OPEN`. Mini-app đang mở giữ nguyên.
- **Mở lại ngay trong callback đóng.** Gọi `open` khi mini-app cũ đang đóng (ví dụ trong callback `USER_CANCEL`, hoặc ngay sau `close()`): SDK hoãn lần mở này đến khi mini-app cũ đã đóng hẳn rồi mới mở. SDK chỉ giữ lần hoãn mới nhất, lần bị thay trả `MINIAPP_ALREADY_OPEN`. Gọi `close()` khi có lần mở đang hoãn thì lần đó bị huỷ với `USER_CANCEL`.
- **Một kết quả đóng mỗi phiên.** Mỗi lần mở, đối tác nhận đúng một kết quả đóng: `USER_CANCEL`, hoặc `onResponse`/`onError` làm mini-app đóng. Sau đó phiên không gọi thêm callback nào. Mini-app chỉ bị che (camera eKYC, webview phụ, view controller khác present lên trên) rồi hiện lại thì không có `USER_CANCEL`.
- **Mở kiểu present** (`.screen`, `.modal`): khi có kết quả đóng, SDK tự đóng mini-app (cùng những gì đang che nó) và gọi callback. Đối tác không cần dismiss.
- **Mở kiểu push** (`from: nil`): khi mini-app tự đóng (nút đóng trong mini-app, hoặc `onResponse`/`onError` làm mini-app đóng), SDK xử lý như 0.8.1: navigation controller chứa mini-app đang được present thì SDK dismiss nó; không được present thì SDK không tự pop, đối tác pop trong callback như trước. Callback vẫn chỉ gọi một lần. Riêng `close()` thì SDK tự gỡ mini-app (cùng màn chờ `PayME` ngay dưới nó), giữ các màn đối tác đã push phía trên; đã gọi `close()` thì đừng tự pop trong callback `USER_CANCEL`.
- **Không khởi động được mini-app** (máy chủ web cục bộ của SDK không chạy được): `onError` trả `SYSTEM_CANCEL` và mini-app tự đóng, không để lại màn trắng.

### Các action

Tạo `PayMEOpeningParam` bằng các factory sau:

| Factory | Action (`PayMEAction`) | identityToken | Dữ liệu | Mô tả |
| --- | --- | --- | --- | --- |
| `.open(identityToken: String)` | `OPEN` | Bắt buộc | Không | Mở trang chủ ví PayME. Người dùng chưa liên kết ví sẽ đi qua luồng liên kết. |
| `.pay(identityToken: String, data: PayMEPaymentParam)` | `PAY` | Bắt buộc | Bắt buộc | Thanh toán một đơn hàng bằng ví PayME |
| `.payment(identityToken: String? = nil, data: PayMEPaymentDirectParam)` | `PAYMENT` | Tuỳ chọn | Bắt buộc | Thanh toán giao dịch đã tạo sẵn. Không có token: thanh toán như khách vãng lai (thẻ, QR). |
| `.deposit(identityToken: String, data: PayMEPayParam? = nil)` | `DEPOSIT` | Bắt buộc | Tuỳ chọn | Nạp tiền vào ví |
| `.withdraw(identityToken: String, data: PayMEPayParam? = nil)` | `WITHDRAW` | Bắt buộc | Tuỳ chọn | Rút tiền từ ví |
| `.transfer(identityToken: String, data: PayMEPayParam? = nil)` | `TRANSFER` | Bắt buộc | Tuỳ chọn | Chuyển tiền |
| `.transferQR(identityToken: String, data: PayMETransferQRParam)` | `TRANSFER_QR` | Bắt buộc | Bắt buộc | Chuyển tiền từ ví tới tài khoản ngân hàng do đối tác chỉ định |
| `.service(identityToken: String, data: PayMEServiceParam)` | `SERVICE` | Bắt buộc | Bắt buộc | Thanh toán dịch vụ (điện, nước, internet, thẻ cào…) |
| `.kyc(identityToken: String)` | `KYC` | Bắt buộc | Không | Định danh tài khoản (eKYC) |
| `.kalapaKYC(identityToken: String)` | `KalapaKYC` | Bắt buộc | Không | Định danh tài khoản qua Kalapa (bao gồm đọc chip NFC) |
| `.payme()` | `PAYME` | Không dùng | Không | Mở ví PayME đầy đủ. Người dùng tự nhập số điện thoại và đăng nhập bằng PIN. |

Ví dụ:

```swift
// Thanh toán đơn hàng bằng ví
payme.open(
  with: .pay(
    identityToken: identityToken,
    data: PayMEPaymentParam(amount: 100_000, transactionId: "ORDER_123", note: "Thanh toán đơn hàng")),
  from: self,
  type: .modal)

// Thanh toán giao dịch đã tạo sẵn, người dùng là khách vãng lai
payme.open(with: .payment(data: PayMEPaymentDirectParam(transaction: "TRANSACTION_ID")), from: self)

// Nạp tiền với số tiền điền sẵn
payme.open(with: .deposit(identityToken: identityToken, data: PayMEPayParam(amount: 50_000)), from: self)
```

### Tham số dữ liệu

`extraData` ở mọi struct là dữ liệu do đối tác tự định nghĩa, được trả lại cho đối tác khi giao dịch thành công.

**`PayMEPaymentParam`** (dùng cho `.pay`)

| Trường | Kiểu | Bắt buộc | Ý nghĩa |
| --- | --- | --- | --- |
| `amount` | `Int` | Có | Số tiền giao dịch (VND) |
| `transactionId` | `String` | Có | Mã giao dịch phía đối tác |
| `note` | `String?` | Không | Ghi chú giao dịch |
| `ipnUrl` | `String?` | Không | URL server đối tác nhận IPN từ PayME khi giao dịch đổi trạng thái (thành công, thất bại) |
| `extraData` | `[String: Any]?` | Không | Dữ liệu bổ sung của đối tác |
| `isShowResult` | `Bool?` | Không | Hiển thị màn kết quả của PayME. Mặc định `true`. |

**`PayMEPaymentDirectParam`** (dùng cho `.payment`)

| Trường | Kiểu | Bắt buộc | Ý nghĩa |
| --- | --- | --- | --- |
| `transaction` | `String` | Có | Mã giao dịch đã tạo sẵn trên hệ thống PayME |
| `extraData` | `[String: Any]?` | Không | Dữ liệu bổ sung của đối tác |
| `isShowResult` | `Bool?` | Không | Hiển thị màn kết quả của PayME. Mặc định `true`. |

**`PayMEPayParam`** (dùng cho `.deposit`, `.withdraw`, `.transfer`)

| Trường | Kiểu | Bắt buộc | Ý nghĩa |
| --- | --- | --- | --- |
| `amount` | `Int?` | Không | Số tiền điền sẵn (VND). Mặc định `0`: người dùng tự nhập. |
| `description` | `String?` | Không | Mô tả giao dịch |
| `extraData` | `[String: Any]?` | Không | Dữ liệu bổ sung của đối tác |
| `isBackToApp` | `Bool?` | Không | Quay về app đối tác sau khi hoàn tất. Mặc định `true`. |
| `isShowResult` | `Bool?` | Không | Hiển thị màn kết quả của PayME. Mặc định `true`. |

**`PayMETransferQRParam`** (dùng cho `.transferQR`)

| Trường | Kiểu | Bắt buộc | Ý nghĩa |
| --- | --- | --- | --- |
| `amount` | `Int` | Có | Số tiền (VND). Truyền `0` nếu để người dùng tự nhập. |
| `swiftCode` | `String` | Có | Mã SWIFT của ngân hàng nhận |
| `bankNumber` | `String` | Có | Số tài khoản hoặc số thẻ nhận |
| `cardHolder` | `String` | Có | Tên chủ tài khoản nhận |
| `partnerTransaction` | `String?` | Không | Mã giao dịch phía đối tác |
| `note` | `String?` | Không | Ghi chú giao dịch |
| `extraData` | `[String: Any]?` | Không | Dữ liệu bổ sung của đối tác |
| `isShowResult` | `Bool?` | Không | Hiển thị màn kết quả của PayME. Mặc định `true`. |

**`PayMEServiceParam`** (dùng cho `.service`)

| Trường | Kiểu | Bắt buộc | Ý nghĩa |
| --- | --- | --- | --- |
| `service` | `String` | Có | Mã dịch vụ, ví dụ `POWE` (điện), `WATE` (nước), `ADSL` (internet), `TIVI` (truyền hình), `PPMB` (điện thoại trả sau), `MOBILE_CARD`, `MOBILE_TOPUP`, `GAME_CARD` |
| `extraData` | `[String: Any]?` | Không | Dữ liệu bổ sung của đối tác |
| `isBackToApp` | `Bool?` | Không | Quay về app đối tác sau khi hoàn tất. Mặc định `true`. |
| `isShowResult` | `Bool?` | Không | Hiển thị màn kết quả của PayME. Mặc định `true`. |

### getBalance

```swift
public func getBalance(identityToken: String)
```

Lấy số dư ví PayME của người dùng. Kết quả trả về `onResponse` với action `.GetBalance` (`GET_BALANCE`):

| Key | Kiểu | Ý nghĩa |
| --- | --- | --- |
| `linked` | `Bool` | `true` nếu người dùng đã liên kết ví PayME với ứng dụng |
| `balance` | `Int64` | Số dư (VND). Chỉ có khi `linked == true`. |
| `message` | `String` | Thông điệp từ PayME |

Lỗi trả về `onError`: `IDENTITY_TOKEN_REQUIRED`, `401` hoặc mã lỗi mạng (xem [Mã lỗi](#mã-lỗi)).

### getAccountInformation

```swift
public func getAccountInformation(identityToken: String)
```

Lấy thông tin tài khoản PayME của người dùng. Kết quả trả về `onResponse` với action `.GetAccountInfo` (`GET_ACCOUNT_INFO`). `response` là object `accountInfo` do PayME BE trả về, luôn có `accountId` (số). Các trường khác phụ thuộc trạng thái tài khoản.

Lỗi trả về `onError`: `IDENTITY_TOKEN_REQUIRED`, `401` hoặc mã lỗi mạng.

### setLanguage

```swift
public func setLanguage(of language: Locale)
```

Đổi ngôn ngữ hiển thị (`.vi` hoặc `.en`). Áp dụng cho lần mở mini-app tiếp theo.

### close

```swift
public func close(from currentVC: UIViewController? = nil)
```

Đóng mini-app đang mở, dù mở kiểu present hay push, kể cả khi mini-app đang bị che (camera, webview phụ): những gì đang che được đóng cùng. Tham số `from` không còn được dùng và chỉ giữ để tương thích mã nguồn: SDK luôn đóng chính mini-app, không dismiss nhầm màn của đối tác.

- Khi mini-app đã đóng, `onError` trả `USER_CANCEL` một lần.
- Gọi khi SDK đang kiểm tra/tải bản cập nhật (mini-app chưa hiện): huỷ lần mở đó, đóng màn chờ và trả `USER_CANCEL`.
- Gọi khi không có mini-app nào mở: không làm gì.

### PayMEDelegate

```swift
public protocol PayMEDelegate {
  func onError(action: PayMEAction, error: PayMEError)
  func onResponse(action: PayMEAction, response: Dictionary<String, Any>)
}
```

- `action`: action phát sinh sự kiện (`PayMEAction`: `.Open`, `.Pay`, `.Payment`, …, `.GetBalance`, `.GetAccountInfo`).
- `onResponse`: kết quả thành công. Nội dung `response` phụ thuộc action và phiên bản mini-app. Với giao dịch, thường có các key như `transaction`, `state`, `amount`, `amountText`, `method`, `createdAt`, `paymentId`, `partnerTransaction`, `extraData`. Với eKYC: `action`, `code`, `message`.
- `onError`: lỗi hoặc người dùng huỷ. Dùng `error.code` (`String`) để phân loại và `error.description` (`String`, đã bản địa hoá) để hiển thị.

Dự án dùng Swift 6 language mode: khai báo `@preconcurrency PayMEDelegate` khi cho view controller tuân thủ protocol, vì `PayMEDelegate` không gắn với `MainActor` (SDK luôn gọi callback trên main thread).

Luôn xác nhận trạng thái giao dịch cuối cùng ở server (qua `ipnUrl` hoặc API của PayME), không chỉ dựa vào `onResponse` trên app.

```swift
extension WalletViewController {
  func onResponse(action: PayMEAction, response: [String: Any]) {
    switch action {
    case .GetBalance:
      let linked = response["linked"] as? Bool ?? false
      let balance = response["balance"] as? Int64 ?? 0
      print("linked: \(linked), balance: \(balance)")
    default:
      print("\(action.rawValue) completed")
    }
  }

  func onError(action: PayMEAction, error: PayMEError) {
    switch error.code {
    case "USER_CANCEL":
      break // Người dùng đóng mini-app, không phải lỗi
    case "401", "IDENTITY_TOKEN_REQUIRED":
      break // Lấy identityToken mới từ server rồi thử lại
    default:
      showAlert(message: error.description)
    }
  }

  private func showAlert(message: String) {
    let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: .default))
    present(alert, animated: true)
  }
}
```

**`PayMEWalletDelegate`** (thuộc tính `walletDelegate`) dành cho ứng dụng ví PayME (tag thông báo, đổi môi trường). Ứng dụng đối tác thường không cần.

## Mã lỗi

`error.code` có thể nhận các giá trị sau:

| Code | Phát sinh từ | Ý nghĩa | Cách xử lý |
| --- | --- | --- | --- |
| `IDENTITY_TOKEN_REQUIRED` | `open` (action bắt buộc token), `getBalance`, `getAccountInformation` | identityToken rỗng. SDK không gọi mạng và không mở mini-app. | Lấy token từ server rồi gọi lại |
| `401` | `open`, `getBalance`, `getAccountInformation` | identityToken sai hoặc hết hạn. Mini-app (nếu đang mở) tự đóng. | Lấy token mới từ server rồi gọi lại |
| `USER_CANCEL` | `open` | Người dùng đóng mini-app hoặc màn chờ tải bản cập nhật, hoặc mini-app bị đóng bằng `close` | Không coi là lỗi. Mỗi phiên chỉ báo một lần; không gửi nếu mini-app đã đóng bằng một `onResponse`/`onError` khác, và không gửi khi mini-app chỉ bị che. |
| `SYSTEM_CANCEL` | `open` | SDK không khởi động được mini-app trên thiết bị (ví dụ máy chủ web cục bộ không chạy được). Mini-app tự đóng. | Thử mở lại. Báo PayME nếu lặp lại. |
| `MINIAPP_ALREADY_OPEN` | `open` | Đang có mini-app mở hoặc một lần `open` chưa xong; hoặc lần mở đang hoãn bị lần `open` mới thay. Mini-app đang mở giữ nguyên. | Đợi kết quả đóng của mini-app hiện tại, hoặc gọi `close()` rồi mở lại |
| `MINIAPP_CANNOT_PRESENT` | `open` | Không có chỗ hiển thị mini-app: `open(from: nil)` khi `PayME` không nằm trong `UINavigationController` | Truyền `from` là view controller đang hiển thị, hoặc đặt `PayME` vào navigation controller |
| `-1` | `open` | Lỗi chung do mini-app báo; `description` chứa thông điệp. Mini-app thường tự đóng. | Hiển thị `description` |
| Mã khác | `open` | Lỗi nghiệp vụ mini-app chuyển tiếp từ PayME BE | Hiển thị `description`, ghi log `code` để tra cứu với PayME |
| `ENCODE_FAILED` | `getBalance`, `getAccountInformation` | Không mã hoá được request, thường do key thiếu hoặc sai định dạng | Kiểm tra `PayMEKey` |
| `DECODE_FAILED` | `getBalance`, `getAccountInformation` | Không giải mã được phản hồi, thường do `privateKey` không khớp | Kiểm tra `privateKey` và môi trường (`env`) |
| `CONNECTION_LOST` | `getBalance`, `getAccountInformation` | Mất kết nối mạng, hoặc đăng ký thiết bị với PayME không thành công | Kiểm tra mạng, thử lại |
| `TIMED_OUT` | `getBalance`, `getAccountInformation` | Hết thời gian chờ máy chủ | Thử lại |
| `NO_RESPONSE` | `getBalance`, `getAccountInformation` | Máy chủ không trả dữ liệu hợp lệ | Thử lại sau |
| `SERVER` | `getBalance`, `getAccountInformation` | Máy chủ trả lỗi; `description` là thông điệp của máy chủ | Hiển thị `description` |
| `OTHER` | `getBalance`, `getAccountInformation` | Lỗi hệ thống khác; `description` là mô tả của iOS | Thử lại, ghi log |

## Nâng cấp từ 0.7.x

0.8.x bỏ hoàn toàn tham số số điện thoại. Các struct dữ liệu (`PayMEPaymentParam`, `PayMEPayParam`, …), `PayMEDelegate` và `PayMEError` không đổi.

| 0.7.x | 0.8.x |
| --- | --- |
| `pod 'PayME-Miniapp', '~> 0.7.x'` | `pod 'PayME-Miniapp', '0.8.3'` (cần Xcode 26.2+) |
| `.payme(phone:)` | `.payme()` |
| `.open(phone:)` | `.open(identityToken:)` |
| `.kyc(phone:)`, `.kalapaKYC(phone:)` | `.kyc(identityToken:)`, `.kalapaKYC(identityToken:)` |
| `.pay(phone:data:)`, `.service(phone:data:)`, `.transferQR(phone:data:)` | `.pay(identityToken:data:)`, `.service(identityToken:data:)`, `.transferQR(identityToken:data:)` |
| `.deposit(phone:data:)`, `.withdraw(phone:data:)`, `.transfer(phone:data:)` | `.deposit(identityToken:data:)`, `.withdraw(identityToken:data:)`, `.transfer(identityToken:data:)` |
| `.payment(phone:data:)` | `.payment(identityToken:data:)`, token tuỳ chọn |
| `PayMEOpeningParam(action:phone:data:)` (deprecated) | Đã bỏ. Dùng các factory. |
| `getBalance(of:)` | `getBalance(identityToken:)` |
| `getAccountInformation(of:)` | `getAccountInformation(identityToken:)` |
| `getBalance` báo lỗi định danh bằng `linked: false` | identityToken sai hoặc hết hạn trả `onError` code `401`. `linked: false` chỉ còn nghĩa là người dùng chưa liên kết ví. |
| Background Fetch và `handleEventsForBackgroundURLSession` trong tài liệu cũ | Không cần |

Các bước:

1. Xây API ở server để lấy `identityToken` (xem [identityToken](#identitytoken)).
2. Đổi phiên bản pod, chạy `pod repo update` rồi `pod install`.
3. Thay các lời gọi theo bảng trên.
4. Xử lý thêm code `401` và `IDENTITY_TOKEN_REQUIRED` trong `onError`.

## Cập nhật OTA

Giao diện mini-app (web bundle) được đóng sẵn trong SDK và có thể được PayME cập nhật qua mạng (OTA). Đối tác không cần cấu hình gì.

- SDK kiểm tra bản cập nhật mỗi lần gọi `open`.
- Bản cập nhật bắt buộc: SDK hiển thị màn tải trước khi mở mini-app. Lỗi mạng thì hiển thị nút tải lại.
- Bản cập nhật không bắt buộc: không chặn việc mở mini-app.
- Mỗi bản cập nhật được PayME ký số (ECDSA P-256), chỉ tải qua HTTPS từ `static.payme.vn` và được kiểm tra kích thước, SHA-256 trước khi cài. Bản không hợp lệ bị bỏ qua và SDK tiếp tục dùng bản đang có. SDK không bao giờ cài bản cũ hơn bản đang có.
- Nếu mạng của bạn có tường lửa, cho phép truy cập `https://static.payme.vn`.

## Lịch sử phiên bản và hỗ trợ

| Phiên bản | Thay đổi chính |
| --- | --- |
| 0.8.3 | Mỗi phiên một kết quả đóng (`USER_CANCEL` một lần, không báo khi mini-app chỉ bị che). `close()` đóng chính mini-app, bỏ qua `from`. Kiểu push: mini-app tự đóng thì giữ cách xử lý của 0.8.1 (đối tác pop trong callback), `close()` thì SDK tự pop. Thêm `MINIAPP_ALREADY_OPEN`, `MINIAPP_CANNOT_PRESENT`; mở lại trong callback đóng được hoãn đến khi mini-app cũ đóng hẳn. Lỗi khởi động máy chủ web trả `SYSTEM_CANCEL` và đóng mini-app. Mini-app patch 0502. |
| 0.8.2 | Chỉ có tag GitHub, không phát hành lên CocoaPods trunk. Dùng 0.8.3. |
| 0.8.0, 0.8.1 | `identityToken` thay cho số điện thoại. Xem [Nâng cấp từ 0.7.x](#nâng-cấp-từ-07x). |

- Ghi chú phát hành: [GitHub Releases](https://github.com/PayME-Miniapp/native-ios/releases).
- Bộ key, tài liệu API `identityToken/init`, môi trường sandbox và hỗ trợ tích hợp: liên hệ PayME.
