[Tiếng Việt](README.md) | **English**

# PayME Miniapp iOS SDK

An SDK that embeds the PayME Miniapp (wallet, payments, deposit/withdraw/transfer, eKYC, bill payments) into a partner's iOS app.

Current version: pod `PayME-Miniapp` **0.8.3** (SDK 1.0.24, mini-app patch 0502). See the [release history](#changelog-and-support).

> `0.8.0`–`0.8.2` have the same API as `0.8.3`; use `0.8.3`. The `0.8.2` tag exists on GitHub but was never published to CocoaPods trunk.

> Since 0.8.0 the SDK takes an `identityToken` instead of a phone number. This is a breaking change from 0.7.x. See [Upgrading from 0.7.x](#upgrading-from-07x).

## Table of contents

- [Requirements](#requirements)
- [Installation](#installation)
- [App configuration](#app-configuration)
  - [Info.plist](#infoplist)
  - [Capabilities](#capabilities)
- [Quick start](#quick-start)
- [identityToken](#identitytoken)
- [API reference](#api-reference)
  - [Creating PayME](#creating-payme)
  - [PayMEConfig](#paymeconfig)
  - [Opening the mini-app](#opening-the-mini-app)
  - [Actions](#actions)
  - [Data parameters](#data-parameters)
  - [getBalance](#getbalance)
  - [getAccountInformation](#getaccountinformation)
  - [setLanguage](#setlanguage)
  - [close](#close)
  - [PayMEDelegate](#paymedelegate)
- [Error codes](#error-codes)
- [Upgrading from 0.7.x](#upgrading-from-07x)
- [OTA updates](#ota-updates)
- [Changelog and support](#changelog-and-support)

## Requirements

| Component | Version |
| --- | --- |
| iOS (deployment target) | 13.0 or later |
| Xcode | 26.2 or later |
| Swift | Swift 6.2.3 compiler or later (ships with Xcode 26.2). The framework is built with Swift 6.2.3, so older Xcode versions cannot read it. |
| CocoaPods | 1.17.0 or later recommended (the version used to release the SDK) |

The SDK is a dynamic framework (`PayMEMiniApp.xcframework`) distributed through CocoaPods.

## Installation

Add the pod to your `Podfile`:

```ruby
platform :ios, '13.0'
use_frameworks!

target 'YourApp' do
  pod 'PayME-Miniapp', '0.8.3'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      # The framework is built with library evolution, so its dependency pods must be too.
      config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
      # Some dependency pods (e.g. NSLogger) declare an iOS version below 13.0, which fails with libarclite on recent Xcode.
      deployment_target = config.build_settings['IPHONEOS_DEPLOYMENT_TARGET']
      if Gem::Version.new(deployment_target || '0') < Gem::Version.new('13.0')
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
      end
    end
  end
end
```

Then run:

```sh
pod install
```

If your `Podfile` already has a `post_install` block, merge the lines above into it.

You can also install straight from the git tag instead of CocoaPods trunk:

```ruby
pod 'PayME-Miniapp', :git => 'https://github.com/PayME-Miniapp/native-ios.git', :tag => '0.8.3'
```

**When upgrading:**

- Installed from trunk: run `pod repo update` (or `pod install --repo-update`) so CocoaPods sees the new version.
- Installed from a git tag, or 0.8.0 was installed before: clear the cache and reinstall.

  ```sh
  pod cache clean PayME-Miniapp --all
  pod install
  ```

**Projects without `use_frameworks!`:** declare the following pods as dynamic frameworks.

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

## App configuration

### Info.plist

Add the keys below. Each description string appears in the iOS permission prompt, so state the purpose clearly.

![Keys to add to Info.plist](documents/info_plist.png)

| Key | Name shown in Xcode | Purpose |
| --- | --- | --- |
| `NSCameraUsageDescription` | Privacy - Camera Usage Description | Capture ID documents and face for eKYC, face authentication, QR scanning |
| `NSFaceIDUsageDescription` | Privacy - Face ID Usage Description | Authenticate with Face ID instead of the PIN |
| `NSPhotoLibraryUsageDescription` | Privacy - Photo Library Usage Description | Pick a photo from the library (e.g. a QR code image) |
| `NSPhotoLibraryAddUsageDescription` | Privacy - Photo Library Additions Usage Description | Save QR code images to the library |
| `NSContactsUsageDescription` | Privacy - Contacts Usage Description | Pick a phone number from contacts for transfers and mobile top-ups |
| `NFCReaderUsageDescription` | Privacy - NFC Scan Usage Description | Read the chip of the Vietnamese citizen ID card for NFC eKYC |
| `com.apple.developer.nfc.readersession.iso7816.select-identifiers` | ISO7816 application identifiers for NFC Tag Reader Session | AIDs of the ID card chip |

Example:

```xml
<key>NSCameraUsageDescription</key>
<string>The camera is used to verify your identity and scan QR codes</string>
<key>NSFaceIDUsageDescription</key>
<string>Face ID is used to authorize transactions</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Photo library access is used to pick QR code images</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>Photo library access is used to save QR code images</string>
<key>NSContactsUsageDescription</key>
<string>Contacts access is used to pick a phone number</string>
<key>NFCReaderUsageDescription</key>
<string>NFC is used to read the chip of your citizen ID card</string>
<key>com.apple.developer.nfc.readersession.iso7816.select-identifiers</key>
<array>
  <string>A0000002471001</string>
  <string>A0000002472001</string>
  <string>00000000000000</string>
</array>
```

**Opening banking apps (optional).** Some payment flows open a banking app through a deeplink. iOS only opens schemes listed in `LSApplicationQueriesSchemes`. Contact PayME for the list of schemes to declare, for example:

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
  <string>vcbpartner</string>
  <string>bidv.smartbanking.partner</string>
</array>
```

### Capabilities

In Xcode, select your app target → **Signing & Capabilities** → click **+ Capability**.

![Adding a capability in Xcode](documents/capabilities.png)

- Add **Near Field Communication Tag Reading** for NFC eKYC. Xcode adds the `com.apple.developer.nfc.readersession.formats` entitlement with the value `TAG`.

The SDK does not need **Background Modes** (Background Fetch) and does not need `application(_:handleEventsForBackgroundURLSession:completionHandler:)`. Mini-app updates are downloaded while opening, not in the background.

## Quick start

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
      locale: .en)
    payme.delegate = self
  }

  // Your server obtains identityToken from PayME; see the identityToken section.
  func openWallet(identityToken: String) {
    payme.open(with: .open(identityToken: identityToken), from: self, type: .screen)
  }

  func onResponse(action: PayMEAction, response: [String: Any]) { /* handle the result */ }
  func onError(action: PayMEAction, error: PayMEError) { /* see Error codes */ }
}
```

PayME issues the key set (`appId`, `publicKey`, `privateKey`) for your app. Never put real keys in public source code, READMEs or screenshots.

## identityToken

`identityToken` is a string signed by the PayME backend for one of the partner's users. The SDK uses it to identify the user, replacing the phone number used in 0.7.x.

**Obtaining a token:**

1. Your app calls your server to request a token for the signed-in user.
2. Your server calls the PayME backend API `identityToken/init` (server to server) with the user's details. Contact PayME for this API's documentation.
3. Your server returns the token to the app. The app passes it to the SDK (`open`, `getBalance`, `getAccountInformation`).

```
Partner app ──(1)──▶ Partner server ──(2) identityToken/init──▶ PayME backend
     ▲                      │
     └───────(3) token ─────┘
Partner app ──▶ PayME SDK (open / getBalance / getAccountInformation)
```

**Lifetime:** a token is valid for 15 minutes and can be reused within that time. When it expires, get a new one from your server.

**Which actions need a token:**

| Case | identityToken |
| --- | --- |
| Every action except `PAYMENT` and `PAYME`, plus `getBalance` and `getAccountInformation` | Required |
| `PAYMENT` (`.payment`) | Optional. With a token the user can pay with the PayME wallet. Without one the user pays as a guest (card, QR). |
| `PAYME` (`.payme()`) | Not used. The user enters a phone number and logs in with a PIN. |

**Related errors:**

- Empty (or whitespace-only) token: the SDK calls `onError` with code `IDENTITY_TOKEN_REQUIRED`, makes no network call and does not open the mini-app.
- Invalid or expired token: the mini-app closes itself and calls `onError` with code `401`. `getBalance` and `getAccountInformation` also return `401`. Get a new token and retry.

**Security:**

- Only your server may call `identityToken/init`. Never call it from the app and never embed its credentials in the app.
- Keep the token in memory only. Do not log it, persist it (UserDefaults, Keychain, files) or put it in a URL.
- Fetch the token right before opening the mini-app rather than long in advance.
- The SDK does not persist the token, clears it from memory when the mini-app closes and masks it in logs.

## API reference

All `PayME` APIs run on the main thread. `PayMEDelegate` callbacks are also delivered on the main thread.

### Creating PayME

```swift
public init(key: PayMEKey, locale: Locale? = .vi)
```

| Parameter | Type | Required | Meaning |
| --- | --- | --- | --- |
| `key` | `PayMEKey` | Yes | Key set issued by PayME: `PayMEKey(appId:publicKey:privateKey:)` |
| `locale` | `Locale?` (`PayMEMiniApp.Locale`) | No | Display language: `.vi` (default) or `.en` |

| `PayMEKey` field | Type | Meaning |
| --- | --- | --- |
| `appId` | `String` | App ID issued by PayME |
| `publicKey` | `String` | PayME's RSA public key, PEM format (`-----BEGIN PUBLIC KEY-----...`) |
| `privateKey` | `String` | Your app's RSA private key, PEM format as issued by PayME (`-----BEGIN RSA PRIVATE KEY-----...`) |

`PayME` is a `UIViewController`. You do not need to present it yourself: the SDK presents it when needed (for example the update download screen). Keep the `PayME` instance alive for as long as you use the mini-app (for example as a view controller property or in a shared service).

Notes:

- `PayMEMiniApp` declares `Locale` and `Environment` enums whose names clash with `Foundation.Locale` and `SwiftUI.Environment`. Use the short form (`.vi`, `.sbx`) or the full name `PayMEMiniApp.Locale`.
- `delegate` and `walletDelegate` are strong references. If the delegate object also holds `PayME` (for example a view controller that owns `payme` and is its delegate), this creates a retain cycle: use an intermediate object that does not hold `PayME`, or set `payme.delegate = nil` when you are done.

### PayMEConfig

Shared configuration, accessed through `PayMEConfig.instance`. Set it before calling `open`, `getBalance` or `getAccountInformation`.

| Property / function | Type | Default | Meaning |
| --- | --- | --- | --- |
| `env` | `Environment` | `.prod` | PayME environment: `.prod` (production) or `.sbx` (sandbox) |
| `setMode(_:)` | `String` | `"miniapp_product"` | Mini-app update channel. Use `"miniapp_sandbox"` for sandbox. Change it only as instructed by PayME. |
| `locale` / `setLanguage(_:)` | `Locale` | `.vi` | Display language |
| `theme` | `Theme` | PayME colors | Colors of the native eKYC camera screens: `Theme(primary:background:textPrimary:)` |
| `setDebugMode(_:)` | `Bool` | `false` | Enables SDK debug logging. Use during development only; turn it off in release builds. |

Sandbox example:

```swift
PayMEConfig.instance.env = .sbx
PayMEConfig.instance.setMode("miniapp_sandbox")
```

### Opening the mini-app

```swift
public func open(
  with openData: PayMEOpeningParam,
  from currentVC: UIViewController? = nil,
  type: PayMEOpeningType? = .screen
)
```

| Parameter | Type | Required | Meaning |
| --- | --- | --- | --- |
| `openData` | `PayMEOpeningParam` | Yes | The action to open, built with a factory from [Actions](#actions) |
| `currentVC` | `UIViewController?` | Yes (in practice) | The visible view controller. The SDK presents the mini-app from it. Pass `nil` only when `PayME` is already inside a `UINavigationController`: the SDK pushes the mini-app onto that navigation controller (`type` is ignored). With neither, `onError` reports `MINIAPP_CANNOT_PRESENT`. |
| `type` | `PayMEOpeningType?` | No | `.screen` (full screen, default) or `.modal` (bottom sheet; resizable on iOS 15 and later) |

Results are delivered through [`PayMEDelegate`](#paymedelegate).

#### Opening, closing and the closing result

- **One mini-app at a time.** Calling `open` while a mini-app is open, or while another `open` has not finished (update check or download in progress), calls `onError` with `MINIAPP_ALREADY_OPEN`. The open mini-app is not affected.
- **Reopening from the closing callback.** Calling `open` while the previous mini-app is closing (for example inside its `USER_CANCEL` callback, or right after `close()`) is deferred until the previous mini-app has gone. Only the latest deferred call is kept; a replaced one gets `MINIAPP_ALREADY_OPEN`. Calling `close()` while an open is deferred cancels it with `USER_CANCEL`.
- **One closing result per session.** Each open delivers exactly one closing result: `USER_CANCEL`, or the `onResponse`/`onError` that closes the mini-app. The session sends no callback after that. When the mini-app is only covered (eKYC camera, sub-webview, another presented view controller) and comes back, no `USER_CANCEL` is sent.
- **Present mode** (`.screen`, `.modal`): on a closing result the SDK closes the mini-app itself (together with anything covering it) and calls the callback. The partner does not need to dismiss.
- **Push mode** (`from: nil`): when the mini-app closes itself (its close button, or an `onResponse`/`onError` that closes it), the SDK behaves as in 0.8.1: if the navigation controller holding the mini-app is presented, the SDK dismisses it; otherwise the SDK does not pop, and the partner pops in the callback as before. The callback is still called once. `close()` is different: the SDK removes the mini-app itself (together with the `PayME` loading screen right below it) and keeps partner screens pushed above it; after calling `close()`, do not pop again in the `USER_CANCEL` callback.
- **The mini-app cannot start** (the SDK's local web server fails to start): `onError` reports `SYSTEM_CANCEL` and the mini-app closes instead of showing a blank screen.

### Actions

Build a `PayMEOpeningParam` with one of these factories:

| Factory | Action (`PayMEAction`) | identityToken | Data | Description |
| --- | --- | --- | --- | --- |
| `.open(identityToken: String)` | `OPEN` | Required | None | Opens the PayME wallet home. Users who have not linked a wallet go through the linking flow. |
| `.pay(identityToken: String, data: PayMEPaymentParam)` | `PAY` | Required | Required | Pays an order with the PayME wallet |
| `.payment(identityToken: String? = nil, data: PayMEPaymentDirectParam)` | `PAYMENT` | Optional | Required | Pays a pre-created transaction. Without a token the user pays as a guest (card, QR). |
| `.deposit(identityToken: String, data: PayMEPayParam? = nil)` | `DEPOSIT` | Required | Optional | Tops up the wallet |
| `.withdraw(identityToken: String, data: PayMEPayParam? = nil)` | `WITHDRAW` | Required | Optional | Withdraws from the wallet |
| `.transfer(identityToken: String, data: PayMEPayParam? = nil)` | `TRANSFER` | Required | Optional | Transfers money |
| `.transferQR(identityToken: String, data: PayMETransferQRParam)` | `TRANSFER_QR` | Required | Required | Transfers from the wallet to a bank account chosen by the partner |
| `.service(identityToken: String, data: PayMEServiceParam)` | `SERVICE` | Required | Required | Pays a bill or service (electricity, water, internet, prepaid cards, …) |
| `.kyc(identityToken: String)` | `KYC` | Required | None | Verifies the account identity (eKYC) |
| `.kalapaKYC(identityToken: String)` | `KalapaKYC` | Required | None | Verifies the account identity through Kalapa (including NFC chip reading) |
| `.payme()` | `PAYME` | Not used | None | Opens the full PayME wallet. The user enters a phone number and logs in with a PIN. |

Examples:

```swift
// Pay an order with the wallet
payme.open(
  with: .pay(
    identityToken: identityToken,
    data: PayMEPaymentParam(amount: 100_000, transactionId: "ORDER_123", note: "Order payment")),
  from: self,
  type: .modal)

// Pay a pre-created transaction as a guest
payme.open(with: .payment(data: PayMEPaymentDirectParam(transaction: "TRANSACTION_ID")), from: self)

// Deposit with a prefilled amount
payme.open(with: .deposit(identityToken: identityToken, data: PayMEPayParam(amount: 50_000)), from: self)
```

### Data parameters

`extraData` in every struct is partner-defined data, returned to the partner when the transaction succeeds.

**`PayMEPaymentParam`** (for `.pay`)

| Field | Type | Required | Meaning |
| --- | --- | --- | --- |
| `amount` | `Int` | Yes | Transaction amount (VND) |
| `transactionId` | `String` | Yes | Partner-side transaction ID |
| `note` | `String?` | No | Transaction note |
| `ipnUrl` | `String?` | No | Partner server URL that receives PayME IPN calls when the transaction changes state (success, failure) |
| `extraData` | `[String: Any]?` | No | Partner-defined data |
| `isShowResult` | `Bool?` | No | Show PayME's result screen. Defaults to `true`. |

**`PayMEPaymentDirectParam`** (for `.payment`)

| Field | Type | Required | Meaning |
| --- | --- | --- | --- |
| `transaction` | `String` | Yes | ID of the transaction already created in the PayME system |
| `extraData` | `[String: Any]?` | No | Partner-defined data |
| `isShowResult` | `Bool?` | No | Show PayME's result screen. Defaults to `true`. |

**`PayMEPayParam`** (for `.deposit`, `.withdraw`, `.transfer`)

| Field | Type | Required | Meaning |
| --- | --- | --- | --- |
| `amount` | `Int?` | No | Prefilled amount (VND). Defaults to `0`: the user enters it. |
| `description` | `String?` | No | Transaction description |
| `extraData` | `[String: Any]?` | No | Partner-defined data |
| `isBackToApp` | `Bool?` | No | Return to the partner app when done. Defaults to `true`. |
| `isShowResult` | `Bool?` | No | Show PayME's result screen. Defaults to `true`. |

**`PayMETransferQRParam`** (for `.transferQR`)

| Field | Type | Required | Meaning |
| --- | --- | --- | --- |
| `amount` | `Int` | Yes | Amount (VND). Pass `0` to let the user enter it. |
| `swiftCode` | `String` | Yes | SWIFT code of the receiving bank |
| `bankNumber` | `String` | Yes | Receiving account or card number |
| `cardHolder` | `String` | Yes | Receiving account holder name |
| `partnerTransaction` | `String?` | No | Partner-side transaction ID |
| `note` | `String?` | No | Transaction note |
| `extraData` | `[String: Any]?` | No | Partner-defined data |
| `isShowResult` | `Bool?` | No | Show PayME's result screen. Defaults to `true`. |

**`PayMEServiceParam`** (for `.service`)

| Field | Type | Required | Meaning |
| --- | --- | --- | --- |
| `service` | `String` | Yes | Service code, e.g. `POWE` (electricity), `WATE` (water), `ADSL` (internet), `TIVI` (TV), `PPMB` (postpaid mobile), `MOBILE_CARD`, `MOBILE_TOPUP`, `GAME_CARD` |
| `extraData` | `[String: Any]?` | No | Partner-defined data |
| `isBackToApp` | `Bool?` | No | Return to the partner app when done. Defaults to `true`. |
| `isShowResult` | `Bool?` | No | Show PayME's result screen. Defaults to `true`. |

### getBalance

```swift
public func getBalance(identityToken: String)
```

Fetches the user's PayME wallet balance. The result arrives in `onResponse` with action `.GetBalance` (`GET_BALANCE`):

| Key | Type | Meaning |
| --- | --- | --- |
| `linked` | `Bool` | `true` if the user has linked a PayME wallet to your app |
| `balance` | `Int64` | Balance (VND). Present only when `linked == true`. |
| `message` | `String` | Message from PayME |

Errors arrive in `onError`: `IDENTITY_TOKEN_REQUIRED`, `401` or a network code (see [Error codes](#error-codes)).

### getAccountInformation

```swift
public func getAccountInformation(identityToken: String)
```

Fetches the user's PayME account information. The result arrives in `onResponse` with action `.GetAccountInfo` (`GET_ACCOUNT_INFO`). `response` is the `accountInfo` object returned by the PayME backend and always contains `accountId` (a number). Other fields depend on the account state.

Errors arrive in `onError`: `IDENTITY_TOKEN_REQUIRED`, `401` or a network code.

### setLanguage

```swift
public func setLanguage(of language: Locale)
```

Changes the display language (`.vi` or `.en`). Takes effect the next time the mini-app opens.

### close

```swift
public func close(from currentVC: UIViewController? = nil)
```

Closes the open mini-app, whether it was presented or pushed, even while it is covered (camera, sub-webview): whatever covers it is closed too. The `from` parameter is no longer used and is kept only for source compatibility: the SDK always closes the mini-app itself and never dismisses a partner screen by mistake.

- Once the mini-app has closed, `onError` reports `USER_CANCEL` once.
- Called while the SDK is checking or downloading an update (the mini-app is not shown yet): cancels that open, closes the loading screen and reports `USER_CANCEL`.
- Called when no mini-app is open: does nothing.

### PayMEDelegate

```swift
public protocol PayMEDelegate {
  func onError(action: PayMEAction, error: PayMEError)
  func onResponse(action: PayMEAction, response: Dictionary<String, Any>)
}
```

- `action`: the action that produced the event (`PayMEAction`: `.Open`, `.Pay`, `.Payment`, …, `.GetBalance`, `.GetAccountInfo`).
- `onResponse`: a successful result. The content of `response` depends on the action and the mini-app version. Transactions usually include keys such as `transaction`, `state`, `amount`, `amountText`, `method`, `createdAt`, `paymentId`, `partnerTransaction`, `extraData`. eKYC returns `action`, `code`, `message`.
- `onError`: an error or a user cancellation. Use `error.code` (`String`) to classify it and `error.description` (`String`, localized) to display it.

In Swift 6 language mode, declare the conformance as `@preconcurrency PayMEDelegate` on a view controller, because `PayMEDelegate` is not `MainActor`-isolated (the SDK always calls it on the main thread).

Always confirm the final transaction state on your server (through `ipnUrl` or PayME's API) instead of relying only on `onResponse` in the app.

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
      break // The user closed the mini-app; not an error
    case "401", "IDENTITY_TOKEN_REQUIRED":
      break // Get a new identityToken from your server and retry
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

**`PayMEWalletDelegate`** (the `walletDelegate` property) is meant for the PayME wallet app (notification tags, environment switching). Partner apps usually do not need it.

## Error codes

`error.code` can take the following values:

| Code | Raised by | Meaning | Suggested handling |
| --- | --- | --- | --- |
| `IDENTITY_TOKEN_REQUIRED` | `open` (actions that require a token), `getBalance`, `getAccountInformation` | Empty identityToken. The SDK makes no network call and does not open the mini-app. | Get a token from your server and retry |
| `401` | `open`, `getBalance`, `getAccountInformation` | Invalid or expired identityToken. The mini-app (if open) closes itself. | Get a new token from your server and retry |
| `USER_CANCEL` | `open` | The user closed the mini-app or the update loading screen, or it was closed with `close` | Not an error. Reported once per session; not sent when the mini-app already closed with another `onResponse`/`onError`, nor when it is only covered. |
| `SYSTEM_CANCEL` | `open` | The SDK could not start the mini-app on the device (for example the local web server failed to start). The mini-app closes. | Try opening again. Report to PayME if it persists. |
| `MINIAPP_ALREADY_OPEN` | `open` | A mini-app is open or another `open` has not finished; or a deferred open was replaced by a newer `open`. The open mini-app is not affected. | Wait for the current mini-app's closing result, or call `close()` and open again |
| `MINIAPP_CANNOT_PRESENT` | `open` | Nowhere to show the mini-app: `open(from: nil)` while `PayME` is not inside a `UINavigationController` | Pass the visible view controller as `from`, or put `PayME` in a navigation controller |
| `-1` | `open` | Generic error reported by the mini-app; `description` holds the message. The mini-app usually closes. | Show `description` |
| Other codes | `open` | Business error passed through by the mini-app from the PayME backend | Show `description`; log `code` for follow-up with PayME |
| `ENCODE_FAILED` | `getBalance`, `getAccountInformation` | The request could not be encrypted, usually because a key is missing or malformed | Check `PayMEKey` |
| `DECODE_FAILED` | `getBalance`, `getAccountInformation` | The response could not be decrypted, usually because `privateKey` does not match | Check `privateKey` and the environment (`env`) |
| `CONNECTION_LOST` | `getBalance`, `getAccountInformation` | Network connection lost, or device registration with PayME failed | Check the network and retry |
| `TIMED_OUT` | `getBalance`, `getAccountInformation` | The server took too long to respond | Retry |
| `NO_RESPONSE` | `getBalance`, `getAccountInformation` | The server returned no valid data | Retry later |
| `SERVER` | `getBalance`, `getAccountInformation` | The server returned an error; `description` holds its message | Show `description` |
| `OTHER` | `getBalance`, `getAccountInformation` | Other system error; `description` holds the iOS description | Retry and log it |

## Upgrading from 0.7.x

0.8.x removes the phone number parameter entirely. The data structs (`PayMEPaymentParam`, `PayMEPayParam`, …), `PayMEDelegate` and `PayMEError` are unchanged.

| 0.7.x | 0.8.x |
| --- | --- |
| `pod 'PayME-Miniapp', '~> 0.7.x'` | `pod 'PayME-Miniapp', '0.8.3'` (requires Xcode 26.2+) |
| `.payme(phone:)` | `.payme()` |
| `.open(phone:)` | `.open(identityToken:)` |
| `.kyc(phone:)`, `.kalapaKYC(phone:)` | `.kyc(identityToken:)`, `.kalapaKYC(identityToken:)` |
| `.pay(phone:data:)`, `.service(phone:data:)`, `.transferQR(phone:data:)` | `.pay(identityToken:data:)`, `.service(identityToken:data:)`, `.transferQR(identityToken:data:)` |
| `.deposit(phone:data:)`, `.withdraw(phone:data:)`, `.transfer(phone:data:)` | `.deposit(identityToken:data:)`, `.withdraw(identityToken:data:)`, `.transfer(identityToken:data:)` |
| `.payment(phone:data:)` | `.payment(identityToken:data:)`, token optional |
| `PayMEOpeningParam(action:phone:data:)` (deprecated) | Removed. Use the factories. |
| `getBalance(of:)` | `getBalance(identityToken:)` |
| `getAccountInformation(of:)` | `getAccountInformation(identityToken:)` |
| `getBalance` reported identity failures as `linked: false` | An invalid or expired identityToken returns `onError` code `401`. `linked: false` now only means the user has not linked a wallet. |
| Background Fetch and `handleEventsForBackgroundURLSession` in the old docs | Not needed |

Steps:

1. Add a server endpoint that obtains the `identityToken` (see [identityToken](#identitytoken)).
2. Change the pod version, run `pod repo update`, then `pod install`.
3. Replace the calls according to the table above.
4. Handle codes `401` and `IDENTITY_TOKEN_REQUIRED` in `onError`.

## OTA updates

The mini-app UI (a web bundle) ships inside the SDK and PayME can update it over the air (OTA). Partners do not need to configure anything.

- The SDK checks for updates every time `open` is called.
- Mandatory update: the SDK shows a download screen before opening the mini-app, with a reload button on network errors.
- Optional update: it does not block opening the mini-app.
- Every update is digitally signed by PayME (ECDSA P-256), downloaded only over HTTPS from `static.payme.vn`, and checked for size and SHA-256 before installation. Invalid updates are ignored and the SDK keeps the current bundle. The SDK never installs a version older than the current one.
- If your network uses a firewall, allow access to `https://static.payme.vn`.

## Changelog and support

| Version | Main changes |
| --- | --- |
| 0.8.3 | One closing result per session (`USER_CANCEL` once, not sent when the mini-app is only covered). `close()` closes the mini-app itself and ignores `from`. Push mode: when the mini-app closes itself the 0.8.1 behavior is kept (the partner pops in the callback); `close()` pops it in the SDK. New `MINIAPP_ALREADY_OPEN`, `MINIAPP_CANNOT_PRESENT`; opening from the closing callback is deferred until the previous mini-app has gone. A web server start failure reports `SYSTEM_CANCEL` and closes the mini-app. Mini-app patch 0502. |
| 0.8.2 | GitHub tag only, never published to CocoaPods trunk. Use 0.8.3. |
| 0.8.0, 0.8.1 | `identityToken` instead of a phone number. See [Upgrading from 0.7.x](#upgrading-from-07x). |

- Release notes: [GitHub Releases](https://github.com/PayME-Miniapp/native-ios/releases).
- Key sets, `identityToken/init` API documentation, sandbox access and integration support: contact PayME.
