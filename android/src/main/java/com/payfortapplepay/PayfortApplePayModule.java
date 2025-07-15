package com.payfortapplepay;

import androidx.annotation.NonNull;

import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.module.annotations.ReactModule;

@ReactModule(name = PayfortApplePayModule.NAME)
public class PayfortApplePayModule extends ReactContextBaseJavaModule {
  public static final String NAME = "PayfortApplePay";

  public PayfortApplePayModule(ReactApplicationContext reactContext) {
    super(reactContext);
  }

  @Override
  @NonNull
  public String getName() {
    return NAME;
  }

  @ReactMethod
  public void configure(ReadableMap config, Promise promise) {
    // Apple Pay is not available on Android
    promise.resolve(false);
  }

  @ReactMethod
  public void isApplePayAvailable(Promise promise) {
    // Apple Pay is not available on Android
    promise.resolve(false);
  }

  @ReactMethod
  public void createSDKToken(ReadableMap request, Promise promise) {
    promise.reject("PLATFORM_NOT_SUPPORTED", "Apple Pay is not available on Android");
  }

  @ReactMethod
  public void payWithApplePay(ReadableMap request, Promise promise) {
    promise.reject("PLATFORM_NOT_SUPPORTED", "Apple Pay is not available on Android");
  }

  @ReactMethod
  public void getDeviceId(Promise promise) {
    promise.reject("PLATFORM_NOT_SUPPORTED", "This method is iOS specific");
  }
}