[Tiếng Việt](README.md) | **English**

# PayME Miniapp iOS SDK

An SDK for opening the PayME Miniapp (wallet, payments, deposit, withdraw, transfer, bill payments, eKYC) in your iOS app.

Current version: pod `PayME-Miniapp` **0.8.4**.

## Table of contents

1. [Requirements](#requirements)
2. [Installation](#installation)
3. [App configuration](#app-configuration)
4. [Quick start](#quick-start)
5. [identityToken](#identitytoken)
6. [API](#api)
7. [Error codes](#error-codes)
8. [Upgrading from 0.7.x](#upgrading-from-07x)
9. [Support](#support)

## Requirements

- iOS 13.0 or later.
- Xcode 26.2 or later (the SDK is built with Swift 6.2.3; older Xcode versions cannot read it).
- CocoaPods, 1.17.0 or later recommended.
- The `appId`, `publicKey`, `privateKey` key set issued by PayME.
- A server of yours that can call PayME's `identityToken` API.

## Installation

Add to your `Podfile`:

```ruby
# Your app's minimum iOS version (same as `platform :ios`). With Xcode 27 the minimum is '15.0'.
app_min_ios = '13.0'

platform :ios, app_min_ios
use_frameworks!

target 'YourApp' do
  pod 'PayME-Miniapp', '0.8.4'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      # The SDK is built with library evolution, so its dependencies must enable it too
      config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
      # Raise pods whose minimum iOS is lower than the app's
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

- If your `Podfile` already has a `post_install`, merge the above into that block.
- To upgrade the SDK: run `pod install --repo-update`.
- Projects without `use_frameworks!`: declare these pods as dynamic frameworks.

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

## App configuration

Add to `Info.plist` (adjust the descriptions to your app):

```xml
<!-- Open banking apps during payment. Contact PayME for the full scheme list -->
<key>LSApplicationQueriesSchemes</key>
<array>
  <string>vcbpartner</string>
  <string>bidv.smartbanking.partner</string>
</array>
<key>NSCameraUsageDescription</key>
<string>The app uses the camera for identity verification and QR scanning</string>
<key>NSFaceIDUsageDescription</key>
<string>Use Face ID to confirm transactions</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>The app needs photo library access to pick QR code images</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>The app needs to save QR code images to your photo library</string>
<key>NSContactsUsageDescription</key>
<string>Allow contacts access to pick phone numbers quickly</string>
<!-- Read the national ID card chip during eKYC -->
<key>NFCReaderUsageDescription</key>
<string>Read the national ID card chip for identity verification</string>
<key>com.apple.developer.nfc.readersession.iso7816.select-identifiers</key>
<array>
  <string>A0000002471001</string>
  <string>A0000002472001</string>
  <string>00000000000000</string>
</array>
```

In Xcode, open your app target → **Signing & Capabilities** → **+ Capability** → add **Near Field Communication Tag Reading**.

![Near Field Communication Tag Reading](documents/capabilities.png)

## Quick start

```swift
import UIKit
import PayMEMiniApp

final class WalletViewController: UIViewController, PayMEDelegate {
  private var payme: PayME!

  override func viewDidLoad() {
    super.viewDidLoad()
    // Sandbox: PayMEConfig.instance.env = .sbx; PayMEConfig.instance.setMode("miniapp_sandbox")
    payme = PayME(
      key: PayMEKey(
        appId: "<APP_ID>",
        publicKey: "-----BEGIN PUBLIC KEY-----...-----END PUBLIC KEY-----",
        privateKey: "-----BEGIN RSA PRIVATE KEY-----...-----END RSA PRIVATE KEY-----"),
      locale: .vi)
    payme.delegate = self
  }

  // identityToken is fetched from PayME by your server
  func openWallet(identityToken: String) {
    payme.open(with: .open(identityToken: identityToken), from: self, type: .modal)
  }

  func onResponse(action: PayMEAction, response: [String: Any]) { /* result */ }
  func onError(action: PayMEAction, error: PayMEError) { /* see Error codes */ }
}
```

> Do not put real keys in public source code, READMEs or screenshots.

## identityToken

`identityToken` is a string PayME issues for each of your users. Your app passes it every time it opens the Miniapp.

1. Your app calls your server.
2. Your server calls PayME's `token-init` API (`POST /be/ewallet/sdk/token-init`) with the user's information (contact PayME for the API docs). Never call this API from the app.
3. Your app passes the returned `identityToken` to `open`, `getBalance` or `getAccountInformation`.

| Action / function | `identityToken` |
| --- | --- |
| `.payment` | Optional. With it, the user can pay with the PayME wallet; without it, they pay as a guest (card, QR) |
| All other actions, `getBalance`, `getAccountInformation` | Required |

- The string is valid for 15 minutes and can be reused within that time.
- Empty: `onError` returns `IDENTITY_TOKEN_REQUIRED` and the Miniapp does not open.
- Wrong or expired: `onError` returns `401` (the Miniapp closes if open). Get a new string and call again.
- Keep the string in memory only: do not store it, log it, or put it in a URL.

## API

Call every function on the main thread. Results and errors come back through `PayMEDelegate`, also on the main thread.

### Initialization

```swift
PayME(key: PayMEKey(appId:publicKey:privateKey:), locale: .vi)
```

| Parameter | Description |
| --- | --- |
| `appId` | App ID issued by PayME |
| `publicKey` | PayME's RSA public key, PEM format |
| `privateKey` | Your app's RSA private key, PEM format as issued by PayME |
| `locale` | `.vi` (default) or `.en` |

- Keep the `PayME` object alive while you use the Miniapp (for example as a view controller property). You do not need to display it yourself.
- `delegate` is a strong reference. If the delegate also holds `PayME`, you get a retain cycle: set `payme.delegate = nil` when done, or use an intermediate object.
- The SDK's `Locale` and `Environment` clash with `Foundation.Locale` and `SwiftUI.Environment`. Use the short form (`.vi`, `.sbx`) or write `PayMEMiniApp.Locale`.

### PayMEConfig

Shared configuration via `PayMEConfig.instance`. Set it before calling `open`, `getBalance` or `getAccountInformation`.

| Property / function | Description |
| --- | --- |
| `env` | `.prod` (default) or `.sbx` (sandbox) |
| `setMode(_:)` | Defaults to `"miniapp_product"`. For sandbox, use `"miniapp_sandbox"` |
| `theme` | Colors of the eKYC camera screens: `Theme(primary:background:textPrimary:)` |
| `setDebugMode(_:)` | Turns on SDK logs during development. Turn it off in release builds |

### open

```swift
payme.open(with: PayMEOpeningParam, from: UIViewController?, type: PayMEOpeningType?)
```

- `from`: the view controller on screen. The SDK presents the Miniapp from it.
- `type`: `.screen` (full screen, default) or `.modal` (slides up from the bottom).
- Use `from: nil` only when `PayME` is already inside a `UINavigationController`: the SDK pushes the Miniapp onto that navigation and ignores `type`.

| Factory | Purpose | `data` |
| --- | --- | --- |
| `.open(identityToken:)` | Wallet home (opens the linking flow if not linked yet) | None |
| `.kyc(identityToken:)` | Identity verification (eKYC) | None |
| `.kalapaKYC(identityToken:)` | Identity verification via Kalapa (with NFC chip reading) | None |
| `.pay(identityToken:data:)` | Pay for your order | [`PayMEPaymentParam`](#paymepaymentparam-pay) |
| `.payment(identityToken:data:)` | Pay a transaction created via the PayME API | [`PayMEPaymentDirectParam`](#paymepaymentdirectparam-payment) |
| `.transferQR(identityToken:data:)` | Transfer to a bank account | [`PayMETransferQRParam`](#paymetransferqrparam-transferqr) |
| `.service(identityToken:data:)` | Bill payments (electricity, water, cards…) | [`PayMEServiceParam`](#paymeserviceparam-service) |
| `.deposit`, `.withdraw`, `.transfer` `(identityToken:data:)` | Deposit, withdraw, transfer | [`PayMEPayParam`](#paymepayparam-deposit-withdraw-transfer), optional |

```swift
payme.open(
  with: .pay(
    identityToken: identityToken,
    data: PayMEPaymentParam(amount: 10_000, transactionId: "ORDER_123", note: "Order 123")),
  from: self, type: .modal)
payme.open(with: .payment(data: PayMEPaymentDirectParam(transaction: "<TRANSACTION>")), from: self) // guest
payme.open(with: .service(identityToken: identityToken, data: PayMEServiceParam(service: "POWE")), from: self)
payme.open(with: .deposit(identityToken: identityToken, data: PayMEPayParam(amount: 50_000)), from: self)
```

`amount` is an integer in VND. Every `data` parameter below also has two optional fields: `extraData` (`[String: Any]`, your own data, returned when the transaction succeeds) and `isShowResult` (show PayME's result screen, default `true`).

#### PayMEPaymentParam (pay)

| Field | Required | Description |
| --- | --- | --- |
| `amount` | Yes | Amount |
| `transactionId` | Yes | Your transaction ID |
| `note` | No | Note |
| `ipnUrl` | No | URL that receives transaction status notifications |

#### PayMEPaymentDirectParam (payment)

| Field | Required | Description |
| --- | --- | --- |
| `transaction` | Yes | Transaction ID PayME returned when you created the transaction |

#### PayMETransferQRParam (transferQR)

| Field | Required | Description |
| --- | --- | --- |
| `amount` | Yes | Amount (`0` lets the user enter it) |
| `bankNumber` | Yes | Receiving account or card number |
| `swiftCode` | Yes | SWIFT code of the receiving bank |
| `cardHolder` | Yes | Account holder name |
| `note` | No | Note |
| `partnerTransaction` | No | Your transaction ID |

#### PayMEServiceParam (service)

| Field | Required | Description |
| --- | --- | --- |
| `service` | Yes | `POWE` (electricity), `WATE` (water), `ADSL` (internet), `TIVI` (TV), `PPMB` (postpaid), `MOBILE_CARD` (phone card), `MOBILE_TOPUP` (phone top-up), `GAME_CARD` (game card) |
| `isBackToApp` | No | Return to your app when done (default `true`) |

#### PayMEPayParam (deposit, withdraw, transfer)

| Field | Required | Description |
| --- | --- | --- |
| `amount` | No | Prefilled amount (default `0`: the user enters it) |
| `description` | No | Transaction description |
| `isBackToApp` | No | Return to your app when done (default `true`) |

### getBalance, getAccountInformation

```swift
payme.getBalance(identityToken: identityToken)
payme.getAccountInformation(identityToken: identityToken)
```

Results come back through `onResponse`:

- `.GetBalance`: `linked` (whether the wallet is linked), `balance` (`Int64`, present when `linked` is `true`).
- `.GetAccountInfo`: wallet account information, always includes `accountId`.

### setLanguage, close

- `setLanguage(of: .vi | .en)`: changes the language, applied the next time the Miniapp opens.
- `close()`: closes the open Miniapp (even while it is downloading an update) and reports `USER_CANCEL`. Does nothing if no Miniapp is open.

### PayMEDelegate

```swift
func onResponse(action: PayMEAction, response: [String: Any])
func onError(action: PayMEAction, error: PayMEError)
```

| Event | Content | When |
| --- | --- | --- |
| `onResponse` | `action`, `response` | A transaction succeeds, or a `getBalance` / `getAccountInformation` result arrives |
| `onError` | `action`, `error.code`, `error.description` | An error occurs or the user closes the Miniapp |

- `error.description` is localized, ready to display.
- With Swift 6 language mode: declare `@preconcurrency PayMEDelegate`.
- Always confirm the final transaction status on your server (via `ipnUrl` or the PayME API), not only through `onResponse`.

### Opening and closing the Miniapp

- Only one Miniapp can be open at a time. Calling `open` while one is open returns `MINIAPP_ALREADY_OPEN`.
- When Miniapp closes, you get its result exactly once: `onResponse`, `onError`, or `USER_CANCEL` when the user closes it. You can open again right inside that callback.
- Presented (`from: viewController`): the SDK closes the Miniapp itself, then calls the callback. You do not need to dismiss.
- Pushed (`from: nil`), when the Miniapp closes itself (the user taps close, or a transaction finishes): if the navigation is presented, the SDK dismisses it; otherwise you pop in the callback.
- After you call `close()`, the SDK removes the Miniapp in both modes. Do not pop again in the `USER_CANCEL` callback.

## Error codes

| `code` | Meaning | What to do |
| --- | --- | --- |
| `401` | `identityToken` is wrong or expired | Get a new `identityToken` and call again |
| `IDENTITY_TOKEN_REQUIRED` | `identityToken` is missing | Pass an `identityToken` |
| `USER_CANCEL` | The user closed the Miniapp, or you called `close()` | Not an error |
| `SYSTEM_CANCEL` | The SDK could not start the Miniapp on the device | Open again; contact PayME if it repeats |
| `MINIAPP_ALREADY_OPEN` | A Miniapp is already open | Wait for it to close, or call `close()` first |
| `MINIAPP_CANNOT_PRESENT` | Nowhere to show the Miniapp (`from: nil` while `PayME` is not inside a `UINavigationController`) | Pass `from` as the view controller on screen |
| Other codes | Network, server, wrong key or business errors | Show `description`, retry; contact PayME if it repeats |

## Upgrading from 0.7.x

0.8.x replaces the phone number with `identityToken` and is not backward compatible. The `data` structs, `PayMEDelegate` and `PayMEError` are unchanged.

| 0.7.x | 0.8.x |
| --- | --- |
| `.open(phone:)`, `.kyc(phone:)`, `.kalapaKYC(phone:)` | `.open(identityToken:)`, `.kyc(identityToken:)`, `.kalapaKYC(identityToken:)` |
| `.pay(phone:data:)` and other actions with `data` | `.pay(identityToken:data:)`, … |
| `.payment(phone:data:)` | `.payment(identityToken:data:)`, `identityToken` optional |
| `PayMEOpeningParam(action:phone:data:)` | Removed, use the factories |
| `getBalance(of:)`, `getAccountInformation(of:)` | `getBalance(identityToken:)`, `getAccountInformation(identityToken:)` |

1. Server: integrate the `token-init` API (contact PayME).
2. Change the pod to `'0.8.4'`, then run `pod install --repo-update`.
3. Replace every `phone` with `identityToken` as in the table above.
4. Handle the `401` and `IDENTITY_TOKEN_REQUIRED` errors. `linked: false` from `getBalance` now only means the user has not linked a wallet.
5. Build with Xcode 26.2 or later.

## Support

PayME Technology Corporation, email [hotro@payme.vn](mailto:hotro@payme.vn). For the key set, the sandbox environment, the `token-init` API docs and the `PAYMENT` transaction creation API: contact PayME.

Release notes: [GitHub Releases](https://github.com/PayME-Miniapp/native-ios/releases).
