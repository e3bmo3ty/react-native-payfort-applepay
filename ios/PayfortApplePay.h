#import <React/RCTBridgeModule.h>
#import <PassKit/PassKit.h>

#ifdef RCT_NEW_ARCH_ENABLED
#import "RNPayfortApplePaySpec.h"

@interface PayfortApplePay : NSObject <NativePayfortApplePaySpec, PKPaymentAuthorizationViewControllerDelegate>
#else
#import <React/RCTBridgeModule.h>

@interface PayfortApplePay : NSObject <RCTBridgeModule, PKPaymentAuthorizationViewControllerDelegate>
#endif

@end