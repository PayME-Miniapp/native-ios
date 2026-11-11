**Tiếng Việt** | [English](README.en.md)

# PayME Miniapp iOS SDK

SDK để mở PayME Miniapp (ví, thanh toán, nạp, rút, chuyển tiền, thanh toán dịch vụ, eKYC) trong ứng dụng iOS của bạn.

Phiên bản hiện tại: pod `PayME-Miniapp` **0.9.1** (bàn phím tự bật khi Miniapp mở ô nhập PIN/OTP, như trước 0.7.6).

## Mục lục

1. [Yêu cầu](#yêu-cầu)
2. [Cài đặt](#cài-đặt)
3. [Cấu hình ứng dụng](#cấu-hình-ứng-dụng)
4. [Bắt đầu nhanh](#bắt-đầu-nhanh)
5. [identityToken](#identitytoken)
6. [API](#api)
7. [Mã lỗi](#mã-lỗi)
8. [Nâng cấp lên 0.9.0](#nâng-cấp-lên-090)
9. [Nâng cấp từ 0.7.x](#nâng-cấp-từ-07x)
10. [Hỗ trợ](#hỗ-trợ)

## Yêu cầu

- iOS 13.0 trở lên.
- Xcode 26.2 trở lên (SDK build bằng Swift 6.2.3, Xcode cũ hơn không đọc được).
- CocoaPods, khuyến nghị 1.17.0 trở lên.
- Server của bạn gọi được API cấp `identityToken` của PayME (bằng bộ key PayME cấp cho server).

## Cài đặt

Thêm vào `Podfile`:

```ruby
# Mức iOS tối thiểu của ứng dụng (giống `platform :ios`). Build bằng Xcode 27 thì tối thiểu '15.0'.
app_min_ios = '13.0'

platform :ios, app_min_ios
use_frameworks!

target 'YourApp' do
  pod 'PayME-Miniapp', '0.9.1'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      # SDK build với library evolution, các pod phụ thuộc cũng phải bật
      config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
      # Nâng pod có iOS tối thiểu thấp hơn ứng dụng
      if config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'].to_f < app_min_ios.to_f
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = app_min_ios
      end
    end
  end
end
```

```sh
pod install
```

- `Podfile` đã có `post_install`: gộp nội dung trên vào khối đó.
- Nâng phiên bản SDK: chạy `pod install --repo-update`.
- Dự án không dùng `use_frameworks!`: khai báo các pod sau là dynamic framework.

  ```ruby
  $dynamic_framework = [
    'PayME-Miniapp', 'CryptoSwift', 'SwiftyRSA', 'GCDWebServer', 'NSLogger', 'lottie-ios',
    'SwiftyJSON', 'ZIPFoundation', 'Mixpanel-swift', 'MixpanelSwiftCommon', 'jsonlogic', 'json-enum'
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

Thêm vào `Info.plist` (sửa câu mô tả theo ứng dụng của bạn):

```xml
<!-- Mở app ngân hàng khi thanh toán. Liên hệ PayME để nhận danh sách scheme đầy đủ -->
<key>LSApplicationQueriesSchemes</key>
<array>
  <string>vcbpartner</string>
  <string>bidv.smartbanking.partner</string>
</array>
<key>NSCameraUsageDescription</key>
<string>Ứng dụng cần dùng máy ảnh để định danh và quét mã QR</string>
<key>NSFaceIDUsageDescription</key>
<string>Dùng Face ID để xác thực giao dịch</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Ứng dụng cần truy cập thư viện ảnh để chọn ảnh mã QR</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>Ứng dụng cần lưu ảnh mã QR vào thư viện ảnh</string>
<key>NSContactsUsageDescription</key>
<string>Cho phép truy cập danh bạ để chọn nhanh số điện thoại</string>
<!-- Đọc chip CCCD khi eKYC -->
<key>NFCReaderUsageDescription</key>
<string>Đọc chip căn cước công dân để định danh</string>
<key>com.apple.developer.nfc.readersession.iso7816.select-identifiers</key>
<array>
  <string>A0000002471001</string>
  <string>A0000002472001</string>
  <string>00000000000000</string>
</array>
```

Trong Xcode, vào target ứng dụng → **Signing & Capabilities** → **+ Capability** → thêm **Near Field Communication Tag Reading**.

![Near Field Communication Tag Reading](documents/capabilities.png)

## Bắt đầu nhanh

```swift
import UIKit
import PayMEMiniApp

final class WalletViewController: UIViewController, PayMEDelegate {
  private var payme: PayME!

  override func viewDidLoad() {
    super.viewDidLoad()
    // Sandbox: PayMEConfig.instance.env = .sbx; PayMEConfig.instance.setMode("miniapp_sandbox")
    payme = PayME(locale: .vi)
    payme.delegate = self
  }

  // identityToken do server của bạn lấy từ PayME
  func openWallet(identityToken: String) {
    payme.open(with: .open(identityToken: identityToken), from: self, type: .modal)
  }

  func onResponse(action: PayMEAction, response: [String: Any]) { /* kết quả */ }
  func onError(action: PayMEAction, error: PayMEError) { /* xem Mã lỗi */ }
}
```

## identityToken

`identityToken` là chuỗi PayME cấp cho từng người dùng của bạn. Ứng dụng truyền chuỗi này mỗi lần mở Miniapp.

1. Ứng dụng gọi server của bạn.
2. Server của bạn gọi API `token-init` (`POST /be/ewallet/sdk/token-init`) của PayME với thông tin người dùng (liên hệ PayME để nhận tài liệu API). Không gọi API này từ ứng dụng.
3. Ứng dụng truyền `identityToken` nhận được vào `open`, `getBalance` hoặc `getAccountInformation`.

| Action / hàm | `identityToken` |
| --- | --- |
| `.payment` | Tuỳ chọn. Có thì người dùng trả được bằng ví PayME; không có thì thanh toán như khách vãng lai (thẻ, QR) |
| Các action còn lại, `getBalance`, `getAccountInformation` | Bắt buộc |

- Chuỗi có hiệu lực 15 phút, dùng lại được trong thời gian đó.
- Rỗng: `onError` trả `IDENTITY_TOKEN_REQUIRED`, Miniapp không mở.
- Sai hoặc hết hạn: `onError` trả `401` (Miniapp đóng nếu đang mở). Lấy chuỗi mới rồi gọi lại.
- Chỉ giữ chuỗi trong bộ nhớ: không lưu, không ghi log, không đưa vào URL.

## API

Gọi mọi hàm trên main thread. Kết quả và lỗi trả về qua `PayMEDelegate`, cũng trên main thread.

### Khởi tạo

```swift
PayME(locale: .vi)
```

| Tham số | Mô tả |
| --- | --- |
| `locale` | `.vi` (mặc định) hoặc `.en` |

- Ứng dụng không cần truyền key: SDK đã có sẵn.
- Giữ đối tượng `PayME` suốt thời gian dùng Miniapp (ví dụ là thuộc tính của view controller). Bạn không cần tự hiển thị nó.
- `delegate` là tham chiếu mạnh. Nếu delegate cũng giữ `PayME` thì có vòng tham chiếu: gán `payme.delegate = nil` khi không dùng nữa, hoặc dùng một object trung gian.
- `Locale` và `Environment` của SDK trùng tên với `Foundation.Locale` và `SwiftUI.Environment`. Dùng dạng rút gọn (`.vi`, `.sbx`) hoặc ghi `PayMEMiniApp.Locale`.

### PayMEConfig

Cấu hình dùng chung qua `PayMEConfig.instance`. Đặt trước khi gọi `open`, `getBalance` hoặc `getAccountInformation`.

| Thuộc tính / hàm | Mô tả |
| --- | --- |
| `env` | `.prod` (mặc định) hoặc `.sbx` (sandbox) |
| `setMode(_:)` | Mặc định `"miniapp_product"`. Khi chạy sandbox, dùng `"miniapp_sandbox"` |
| `theme` | Màu các màn camera eKYC: `Theme(primary:background:textPrimary:)` |
| `setDebugMode(_:)` | Bật log của SDK khi phát triển. Tắt ở bản phát hành |

### open

```swift
payme.open(with: PayMEOpeningParam, from: UIViewController?, type: PayMEOpeningType?)
```

- `from`: view controller đang hiển thị. SDK present Miniapp từ view controller này.
- `type`: `.screen` (toàn màn hình, mặc định) hoặc `.modal` (trượt từ dưới lên).
- `from: nil` chỉ dùng khi `PayME` đã nằm trong một `UINavigationController`: SDK push Miniapp vào navigation đó, bỏ qua `type`.

| Factory | Chức năng | `data` |
| --- | --- | --- |
| `.open(identityToken:)` | Trang chủ ví (chưa liên kết thì mở luồng liên kết) | Không có |
| `.kyc(identityToken:)` | Định danh (eKYC) | Không có |
| `.kalapaKYC(identityToken:)` | Định danh qua Kalapa (có đọc chip NFC) | Không có |
| `.pay(identityToken:data:)` | Thanh toán đơn hàng của bạn | [`PayMEPaymentParam`](#paymepaymentparam-pay) |
| `.payment(identityToken:data:)` | Thanh toán giao dịch đã tạo qua API PayME | [`PayMEPaymentDirectParam`](#paymepaymentdirectparam-payment) |
| `.transferQR(identityToken:data:)` | Chuyển tiền tới tài khoản ngân hàng | [`PayMETransferQRParam`](#paymetransferqrparam-transferqr) |
| `.service(identityToken:data:)` | Thanh toán dịch vụ (điện, nước, thẻ…) | [`PayMEServiceParam`](#paymeserviceparam-service) |
| `.deposit`, `.withdraw`, `.transfer` `(identityToken:data:)` | Nạp, rút, chuyển tiền | [`PayMEPayParam`](#paymepayparam-deposit-withdraw-transfer), tuỳ chọn |

```swift
payme.open(
  with: .pay(
    identityToken: identityToken,
    data: PayMEPaymentParam(amount: 10_000, transactionId: "ORDER_123", note: "Đơn hàng 123")),
  from: self, type: .modal)
payme.open(with: .payment(data: PayMEPaymentDirectParam(transaction: "<TRANSACTION>")), from: self) // khách vãng lai
payme.open(with: .service(identityToken: identityToken, data: PayMEServiceParam(service: "POWE")), from: self)
payme.open(with: .deposit(identityToken: identityToken, data: PayMEPayParam(amount: 50_000)), from: self)
```

`amount` là số nguyên VND. Các tham số `data` dưới đây đều có thêm hai trường tuỳ chọn: `extraData` (`[String: Any]`, dữ liệu riêng của bạn, trả lại khi giao dịch thành công) và `isShowResult` (hiện màn hình kết quả của PayME, mặc định `true`).

#### PayMEPaymentParam (pay)

| Trường | Bắt buộc | Mô tả |
| --- | --- | --- |
| `amount` | Có | Số tiền |
| `transactionId` | Có | Mã giao dịch của bạn |
| `note` | Không | Ghi chú |
| `ipnUrl` | Không | URL nhận thông báo trạng thái giao dịch |

#### PayMEPaymentDirectParam (payment)

| Trường | Bắt buộc | Mô tả |
| --- | --- | --- |
| `transaction` | Có | Mã giao dịch PayME trả về khi bạn tạo giao dịch |

#### PayMETransferQRParam (transferQR)

| Trường | Bắt buộc | Mô tả |
| --- | --- | --- |
| `amount` | Có | Số tiền (`0` để người dùng tự nhập) |
| `bankNumber` | Có | Số tài khoản hoặc số thẻ nhận |
| `swiftCode` | Có | Mã SWIFT của ngân hàng nhận |
| `cardHolder` | Có | Tên chủ tài khoản |
| `note` | Không | Ghi chú |
| `partnerTransaction` | Không | Mã giao dịch của bạn |

#### PayMEServiceParam (service)

| Trường | Bắt buộc | Mô tả |
| --- | --- | --- |
| `service` | Có | `POWE` (điện), `WATE` (nước), `ADSL` (internet), `TIVI` (truyền hình), `PPMB` (trả sau), `MOBILE_CARD` (thẻ điện thoại), `MOBILE_TOPUP` (nạp điện thoại), `GAME_CARD` (thẻ game) |
| `isBackToApp` | Không | Quay về ứng dụng của bạn sau khi xong (mặc định `true`) |

#### PayMEPayParam (deposit, withdraw, transfer)

| Trường | Bắt buộc | Mô tả |
| --- | --- | --- |
| `amount` | Không | Số tiền điền sẵn (mặc định `0`: người dùng tự nhập) |
| `description` | Không | Mô tả giao dịch |
| `isBackToApp` | Không | Quay về ứng dụng của bạn sau khi xong (mặc định `true`) |

### getBalance, getAccountInformation

```swift
payme.getBalance(identityToken: identityToken)
payme.getAccountInformation(identityToken: identityToken)
```

Kết quả trả qua `onResponse`:

- `.GetBalance`: `linked` (đã liên kết ví chưa), `balance` (`Int64`, có khi `linked` = `true`).
- `.GetAccountInfo`: thông tin tài khoản ví, luôn có `accountId`.

### setLanguage, close

- `setLanguage(of: .vi | .en)`: đổi ngôn ngữ, áp dụng cho lần mở Miniapp tiếp theo.
- `close()`: đóng Miniapp đang mở (kể cả khi đang tải bản cập nhật) và báo `USER_CANCEL`. Không có Miniapp mở thì không làm gì.

### PayMEDelegate

```swift
func onResponse(action: PayMEAction, response: [String: Any])
func onError(action: PayMEAction, error: PayMEError)
```

| Sự kiện | Nội dung | Khi nào |
| --- | --- | --- |
| `onResponse` | `action`, `response` | Giao dịch thành công, hoặc có kết quả `getBalance` / `getAccountInformation` |
| `onError` | `action`, `error.code`, `error.description` | Có lỗi hoặc người dùng đóng Miniapp |

- `error.description` đã bản địa hoá, dùng để hiển thị.
- Dùng Swift 6 language mode: khai báo `@preconcurrency PayMEDelegate`.
- Luôn xác nhận trạng thái giao dịch ở server (qua `ipnUrl` hoặc API PayME), không chỉ dựa vào `onResponse`.

### Mở và đóng Miniapp

- Mỗi lúc chỉ mở một Miniapp. Gọi `open` khi đang có Miniapp mở sẽ nhận `MINIAPP_ALREADY_OPEN`.
- Khi Miniapp đóng, bạn nhận kết quả đúng một lần: `onResponse`, `onError`, hoặc `USER_CANCEL` khi người dùng đóng. Có thể mở lại ngay trong callback này.
- Mở kiểu present (`from: viewController`): SDK tự đóng Miniapp rồi gọi callback. Bạn không cần dismiss.
- Mở kiểu push (`from: nil`), khi Miniapp tự đóng (người dùng bấm đóng, hoặc kết thúc giao dịch): navigation được present thì SDK tự dismiss; không thì bạn pop trong callback.
- Sau khi gọi `close()`, SDK tự gỡ Miniapp ở cả hai kiểu. Không pop lại trong callback `USER_CANCEL`.

## Mã lỗi

| `code` | Ý nghĩa | Cách xử lý |
| --- | --- | --- |
| `401` | `identityToken` sai hoặc hết hạn | Lấy `identityToken` mới rồi gọi lại |
| `IDENTITY_TOKEN_REQUIRED` | Thiếu `identityToken` | Truyền `identityToken` |
| `USER_CANCEL` | Người dùng đóng Miniapp, hoặc bạn gọi `close()` | Không phải lỗi |
| `SYSTEM_CANCEL` | SDK không khởi động được Miniapp trên thiết bị | Mở lại; liên hệ PayME nếu lặp lại |
| `MINIAPP_ALREADY_OPEN` | Đang có Miniapp mở | Đợi Miniapp đóng, hoặc gọi `close()` trước |
| `MINIAPP_CANNOT_PRESENT` | Không có chỗ hiển thị Miniapp (`from: nil` khi `PayME` không nằm trong `UINavigationController`) | Truyền `from` là view controller đang hiển thị |
| Mã khác | Lỗi mạng, máy chủ hoặc lỗi nghiệp vụ | Hiển thị `description`, thử lại; liên hệ PayME nếu lặp lại |

## Nâng cấp lên 0.9.0

Đổi `PayME(key: PayMEKey(...), locale:)` thành `PayME(locale:)`. Hàm khởi tạo cũ vẫn chạy (deprecated) và bỏ qua key truyền vào.

## Nâng cấp từ 0.7.x

Bản 0.8.x thay số điện thoại bằng `identityToken` và không tương thích ngược. Các struct `data`, `PayMEDelegate` và `PayMEError` không đổi.

| 0.7.x | 0.8.x |
| --- | --- |
| `.open(phone:)`, `.kyc(phone:)`, `.kalapaKYC(phone:)` | `.open(identityToken:)`, `.kyc(identityToken:)`, `.kalapaKYC(identityToken:)` |
| `.pay(phone:data:)` và các action có `data` | `.pay(identityToken:data:)`, … |
| `.payment(phone:data:)` | `.payment(identityToken:data:)`, `identityToken` tuỳ chọn |
| `PayMEOpeningParam(action:phone:data:)` | Đã bỏ, dùng các factory |
| `getBalance(of:)`, `getAccountInformation(of:)` | `getBalance(identityToken:)`, `getAccountInformation(identityToken:)` |

1. Server: tích hợp API `token-init` (liên hệ PayME).
2. Đổi pod thành `'0.9.1'`, rồi `pod install --repo-update`.
3. Thay mọi `phone` bằng `identityToken` theo bảng trên.
4. Xử lý lỗi `401` và `IDENTITY_TOKEN_REQUIRED`. `getBalance` trả `linked: false` giờ chỉ có nghĩa là người dùng chưa liên kết ví.
5. Build bằng Xcode 26.2 trở lên.

## Hỗ trợ

PayME Technology Corporation, email [hotro@payme.vn](mailto:hotro@payme.vn). Bộ key cho server, môi trường sandbox, tài liệu API `token-init` và API tạo giao dịch `PAYMENT`: liên hệ PayME.

Ghi chú phát hành: [GitHub Releases](https://github.com/PayME-Miniapp/native-ios/releases).
