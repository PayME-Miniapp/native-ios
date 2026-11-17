Pod::Spec.new do |spec|
  spec.name         = 'PayME-Miniapp'
  spec.version      = '0.12.0'
  spec.summary      = 'PayME Miniapp SDK for iOS integration.'
  spec.description  = 'PayME Miniapp SDK for iOS: opens the PayME e-wallet mini-app (payments, deposits, withdrawals, transfers, KYC) inside a partner app.'
  spec.homepage     = 'https://github.com/PayME-Miniapp/native-ios'
  # Zip chỉ chứa xcframework nên không đọc được file LICENSE: ghi thẳng nội dung.
  spec.license      = { :type => 'MIT', :text => <<-LICENSE
Copyright (c) 2022 x-oauth-basic <dattm@payme.vn>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
  LICENSE
  }
  spec.author       = { 'DatTM' => 'dattm@payme.vn' }

  spec.ios.deployment_target = '13.0'
  spec.swift_version = '5.9'
  # Binary nằm ở asset của GitHub Release (không commit vào git từ 0.11.0). Cùng zip, cùng sha256 với SPM.
  spec.source       = {
    :http => "https://github.com/PayME-Miniapp/native-ios/releases/download/#{spec.version}/PayMEMiniApp.xcframework.zip",
    :sha256 => 'be1a36397215ca954c56af4710556cc7fa1f903017782d607b1e91d399588e3f'
  }
  spec.vendored_frameworks = 'PayMEMiniApp.xcframework'

  spec.dependency 'GCDWebServer', '~> 3.0'
  spec.dependency 'SwiftyJSON', '~> 5.0'
  spec.dependency 'lottie-ios', '~> 4.6.0'
  spec.dependency 'CryptoSwift', '~> 1.10.0'
  spec.dependency 'SwiftyRSA'
  spec.dependency 'KalapaEkycSDK', '~> 2.8.0'

  spec.pod_target_xcconfig = { 'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'YES' }
end
