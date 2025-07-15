import type { TurboModule } from 'react-native';
import { TurboModuleRegistry } from 'react-native';

export interface PayFortEnvironment {
  environment: 'sandbox' | 'production';
  access_code: string;
  merchant_identifier: string;
  sha_request_phrase: string;
}

export interface PayFortApplePayRequest {
  command?: string;
  currency: string;
  language?: string;
  amount: string;
  merchant_reference: string;
  merchant_extra?: string;
  merchant_extra1?: string;
  merchant_extra2?: string;
  merchant_extra3?: string;
  customer_email: string;
  sdk_token: string;
  apple_pay_merchant_identifier: string;
  currencyType?: string;
  arrItem?: Array<{
    price: string;
    productName: string;
  }>;
  isLive?: boolean;
}

export interface PayFortSDKTokenRequest {
  access_code: string;
  language?: string;
  merchant_identifier: string;
  service_command: string;
}

export interface PayFortApplePayResponse {
  response_code: string;
  response_message: string;
  merchant_reference: string;
  fort_id?: string;
  payment_option?: string;
  authorization_code?: string;
  card_number?: string;
  expiry_date?: string;
  card_holder_name?: string;
  status?: string;
  [key: string]: any;
}

export interface PayFortSDKTokenResponse {
  response_code: string;
  response_message: string;
  sdk_token: string;
}

export interface Spec extends TurboModule {
  configure(config: PayFortEnvironment): Promise<boolean>;
  isApplePayAvailable(): Promise<boolean>;
  createSDKToken(request: PayFortSDKTokenRequest): Promise<PayFortSDKTokenResponse>;
  payWithApplePay(request: PayFortApplePayRequest): Promise<PayFortApplePayResponse>;
  getDeviceId(): Promise<string>;
}

export default TurboModuleRegistry.getEnforcing<Spec>('PayfortApplePay');