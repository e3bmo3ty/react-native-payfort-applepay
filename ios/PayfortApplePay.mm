#import "PayfortApplePay.h"
#import <React/RCTUtils.h>
#import <React/RCTLog.h>

#ifdef RCT_NEW_ARCH_ENABLED
#import "RNPayfortApplePaySpec.h"
#endif

// Import PayFort SDK - adjust path as needed
#import "PayFortSDK/PayFortSDK.h"

@interface PayfortApplePay ()
@property (nonatomic, strong) PayFortController *payFortController;
@property (nonatomic, strong) RCTPromiseResolveBlock currentResolve;
@property (nonatomic, strong) RCTPromiseRejectBlock currentReject;
@property (nonatomic, strong) NSDictionary *currentRequest;
@property (nonatomic, strong) NSDictionary *currentConfig;
@end

@implementation PayfortApplePay

RCT_EXPORT_MODULE()

- (instancetype)init {
    self = [super init];
    if (self) {
        self.payFortController = [[PayFortController alloc] init];
    }
    return self;
}

RCT_EXPORT_METHOD(configure:(NSDictionary *)config
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    
    NSString *environment = config[@"environment"];
    NSString *accessCode = config[@"access_code"];
    NSString *merchantIdentifier = config[@"merchant_identifier"];
    NSString *shaRequestPhrase = config[@"sha_request_phrase"];
    
    if (!environment || !accessCode || !merchantIdentifier || !shaRequestPhrase) {
        reject(@"INVALID_CONFIG", @"Missing required configuration parameters", nil);
        return;
    }
    
    // Store configuration for later use
    self.currentConfig = config;
    
    // Configure PayFort environment
    PayFortEnviroment env = [environment isEqualToString:@"production"] ? 
        PayFortEnviromentProduction : PayFortEnviromentSandBox;
    
    self.payFortController = [[PayFortController alloc] initWithEnviroment:env];
    
    resolve(@YES);
}

RCT_EXPORT_METHOD(isApplePayAvailable:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    
    BOOL isAvailable = [PKPaymentAuthorizationViewController canMakePayments];
    resolve(@(isAvailable));
}

RCT_EXPORT_METHOD(getDeviceId:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    
    NSString *deviceId = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    resolve(deviceId ?: @"");
}

RCT_EXPORT_METHOD(createSDKToken:(NSDictionary *)request
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    
    if (!self.currentConfig) {
        reject(@"NOT_CONFIGURED", @"Module not configured. Call configure() first.", nil);
        return;
    }
    
    NSMutableDictionary *tokenRequest = [NSMutableDictionary dictionary];
    
    // Required parameters
    [tokenRequest setObject:request[@"access_code"] ?: @"" forKey:@"access_code"];
    [tokenRequest setObject:request[@"merchant_identifier"] ?: @"" forKey:@"merchant_identifier"];
    [tokenRequest setObject:request[@"service_command"] ?: @"SDK_TOKEN" forKey:@"service_command"];
    [tokenRequest setObject:request[@"language"] ?: @"en" forKey:@"language"];
    
    // Add device ID
    NSString *deviceId = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    [tokenRequest setObject:deviceId forKey:@"device_id"];
    
    [self.payFortController callValidateAPIWith:tokenRequest
                                    showLoading:^(BOOL show) {
                                        // Handle loading state if needed
                                        RCTLogInfo(@"PayFort loading: %@", show ? @"YES" : @"NO");
                                    }
                                        success:^(NSDictionary *requestDic, NSDictionary *responeDic) {
                                            NSString *responseCode = responeDic[@"response_code"];
                                            if ([responseCode isEqualToString:@"22000"]) {
                                                resolve(responeDic);
                                            } else {
                                                NSString *message = responeDic[@"response_message"] ?: @"Failed to generate SDK token";
                                                reject(@"TOKEN_ERROR", message, nil);
                                            }
                                        }
                                          faild:^(NSDictionary *requestDic, NSDictionary *responeDic, NSString *message) {
                                              reject(@"TOKEN_ERROR", message ?: @"Failed to generate SDK token", nil);
                                          }];
}

RCT_EXPORT_METHOD(payWithApplePay:(NSDictionary *)request
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    
    if (!self.currentConfig) {
        reject(@"NOT_CONFIGURED", @"Module not configured. Call configure() first.", nil);
        return;
    }
    
    self.currentResolve = resolve;
    self.currentReject = reject;
    self.currentRequest = request;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self presentApplePayWithRequest:request];
    });
}

- (void)presentApplePayWithRequest:(NSDictionary *)request {
    PKPaymentRequest *paymentRequest = [[PKPaymentRequest alloc] init];
    
    // Configure payment request from your existing implementation
    paymentRequest.merchantIdentifier = request[@"apple_pay_merchant_identifier"];
    paymentRequest.supportedNetworks = @[PKPaymentNetworkVisa, PKPaymentNetworkMasterCard, PKPaymentNetworkAmex];
    paymentRequest.merchantCapabilities = PKMerchantCapability3DS;
    paymentRequest.countryCode = @"SA"; // From your implementation
    paymentRequest.currencyCode = request[@"currency"] ?: @"SAR";
    
    // Create payment summary items from arrItem
    NSMutableArray *summaryItems = [NSMutableArray array];
    NSArray *arrItem = request[@"arrItem"];
    
    if (arrItem && [arrItem isKindOfClass:[NSArray class]]) {
        for (NSDictionary *item in arrItem) {
            NSString *priceString = item[@"price"];
            NSString *productName = item[@"productName"];
            
            if (priceString && productName) {
                // Convert from smallest currency unit (fils) to main unit
                NSDecimalNumber *amount = [NSDecimalNumber decimalNumberWithString:priceString];
                amount = [amount decimalNumberByDividingBy:[NSDecimalNumber decimalNumberWithString:@"100"]];
                
                PKPaymentSummaryItem *item = [PKPaymentSummaryItem summaryItemWithLabel:productName amount:amount];
                [summaryItems addObject:item];
            }
        }
    } else {
        // Fallback to amount parameter
        NSString *amountString = request[@"amount"];
        NSDecimalNumber *amount = [NSDecimalNumber decimalNumberWithString:amountString];
        amount = [amount decimalNumberByDividingBy:[NSDecimalNumber decimalNumberWithString:@"100"]];
        
        PKPaymentSummaryItem *totalItem = [PKPaymentSummaryItem summaryItemWithLabel:@"Total" amount:amount];
        [summaryItems addObject:totalItem];
    }
    
    paymentRequest.paymentSummaryItems = summaryItems;
    
    // Present Apple Pay
    PKPaymentAuthorizationViewController *applePayController = 
        [[PKPaymentAuthorizationViewController alloc] initWithPaymentRequest:paymentRequest];
    
    if (!applePayController) {
        if (self.currentReject) {
            self.currentReject(@"APPLEPAY_ERROR", @"Failed to create Apple Pay controller", nil);
            [self clearCurrentPromise];
        }
        return;
    }
    
    applePayController.delegate = self;
    
    UIViewController *rootViewController = RCTKeyWindow().rootViewController;
    [rootViewController presentViewController:applePayController animated:YES completion:nil];
}

#pragma mark - PKPaymentAuthorizationViewControllerDelegate

- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller
                       didAuthorizePayment:(PKPayment *)payment
                                completion:(void (^)(PKPaymentAuthorizationStatus))completion {
    
    // Process payment with PayFort using your existing logic
    NSMutableDictionary *payfortRequest = [NSMutableDictionary dictionaryWithDictionary:self.currentRequest];
    
    // Set required PayFort parameters
    [payfortRequest setObject:@"PURCHASE" forKey:@"command"];
    [payfortRequest setObject:@"APPLE_PAY" forKey:@"digital_wallet"];
    
    // Add device ID
    NSString *deviceId = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    [payfortRequest setObject:deviceId forKey:@"device_id"];
    
    // Ensure all your parameters are included
    if (self.currentRequest[@"merchant_extra"]) {
        [payfortRequest setObject:self.currentRequest[@"merchant_extra"] forKey:@"merchant_extra"];
    }
    if (self.currentRequest[@"merchant_extra1"]) {
        [payfortRequest setObject:self.currentRequest[@"merchant_extra1"] forKey:@"merchant_extra1"];
    }
    if (self.currentRequest[@"merchant_extra2"]) {
        [payfortRequest setObject:self.currentRequest[@"merchant_extra2"] forKey:@"merchant_extra2"];
    }
    if (self.currentRequest[@"merchant_extra3"]) {
        [payfortRequest setObject:self.currentRequest[@"merchant_extra3"] forKey:@"merchant_extra3"];
    }
    
    UIViewController *rootViewController = RCTKeyWindow().rootViewController;
    
    [self.payFortController callPayFortForApplePayWithRequest:payfortRequest
                                              applePayPayment:payment
                                        currentViewController:rootViewController
                                                      success:^(NSDictionary *requestDic, NSDictionary *responeDic) {
                                                          completion(PKPaymentAuthorizationStatusSuccess);
                                                          
                                                          if (self.currentResolve) {
                                                              self.currentResolve(responeDic);
                                                              [self clearCurrentPromise];
                                                          }
                                                      }
                                                        faild:^(NSDictionary *requestDic, NSDictionary *responeDic, NSString *message) {
                                                            completion(PKPaymentAuthorizationStatusFailure);
                                                            
                                                            if (self.currentReject) {
                                                                NSString *errorMessage = message ?: @"Payment failed";
                                                                self.currentReject(@"PAYMENT_ERROR", errorMessage, nil);
                                                                [self clearCurrentPromise];
                                                            }
                                                        }];
}

- (void)paymentAuthorizationViewControllerDidFinish:(PKPaymentAuthorizationViewController *)controller {
    [controller dismissViewControllerAnimated:YES completion:^{
        // If we still have a pending promise, it means the user cancelled
        if (self.currentReject) {
            self.currentReject(@"USER_CANCELLED", @"User cancelled the payment", nil);
            [self clearCurrentPromise];
        }
    }];
}

- (void)clearCurrentPromise {
    self.currentResolve = nil;
    self.currentReject = nil;
    self.currentRequest = nil;
}

#ifdef RCT_NEW_ARCH_ENABLED
- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
    (const facebook::react::ObjCTurboModule::InitParams &)params
{
    return std::make_shared<facebook::react::NativePayfortApplePaySpecJSI>(params);
}
#endif

@end