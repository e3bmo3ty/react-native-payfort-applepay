# react-native-payfort-applepay

A comprehensive React Native Turbo Native Module for PayFort (Amazon Payment Services) Apple Pay integration with full parameter support.

## Features

- ✅ Full PayFort Apple Pay integration
- ✅ Support for all PayFort parameters (merchant_extra, merchant_extra1, etc.)
- ✅ Turbo Native Module architecture (New Architecture ready)
- ✅ TypeScript support with complete type definitions
- ✅ iOS native implementation with proper delegate handling
- ✅ Graceful Android handling (Apple Pay not available)
- ✅ Comprehensive error handling and user cancellation support

## Installation

```sh
npm install react-native-payfort-applepay
# or
yarn add react-native-payfort-applepay
```

### iOS Setup

#### 1. Add PayFort SDK

Download the PayFort SDK from [Amazon Payment Services](https://paymentservices-reference.payfort.com/docs/api/build/index.html#apple-pay-sdk-service) and add it to your iOS project:

1. Download `PayFortSDK.xcframework`
2. Drag and drop it into your iOS project in Xcode
3. Make sure it's added to your target's "Frameworks, Libraries, and Embedded Content"

#### 2. Enable Apple Pay Capability

1. In Xcode, select your project
2. Go to "Signing & Capabilities" tab
3. Click "+ Capability" and add "Apple Pay"
4. Configure your merchant identifiers

#### 3. Configure Info.plist

Add the following to your `Info.plist`:

```xml
<key>NSApplePayCapability</key>
<true/>
```

#### 4. Update Podfile (if needed)

If you encounter linking issues, add this to your `Podfile`:

```ruby
target 'YourApp' do
  # ... other dependencies
  
  # Add this if you have linking issues with PayFort SDK
  pod 'react-native-payfort-applepay', :path => '../node_modules/react-native-payfort-applepay'
end
```

### Android

Apple Pay is not available on Android. The module will return appropriate responses indicating platform not supported.

## Usage

### Basic Implementation

```javascript
import PayfortApplePay from 'react-native-payfort-applepay';

// 1. Configure the module (call this once in your app initialization)
await PayfortApplePay.configure({
  environment: 'sandbox', // or 'production'
  access_code: 'your_access_code',
  merchant_identifier: 'your_merchant_identifier',
  sha_request_phrase: 'your_sha_request_phrase'
});

// 2. Check if Apple Pay is available
const isAvailable = await PayfortApplePay.isApplePayAvailable();