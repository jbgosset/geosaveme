/**
 * GeoSaveMe — Market Configuration
 *
 * All market-specific values live here or in .env.{market} files.
 * NEVER hardcode country-specific data anywhere else in the codebase.
 *
 * To add a new market:
 * 1. Create .env.{market} with the values below
 * 2. Create i18n/{locale}.json
 * 3. Review legal/ folder for local compliance requirements
 */

export interface MarketConfig {
  /** e.g. '112' | '911' | '999' | '000' */
  emergencyNumber: string;
  /** e.g. '17' for Police (FR), '911' for Police (US) */
  policeNumber: string;
  /** e.g. '18' for Fire (FR), '911' for Fire (US) */
  fireNumber: string;
  /** e.g. '15' for SAMU (FR), '911' for EMS (US) */
  emsNumber: string;
  /** 'metric' | 'imperial' */
  distanceUnit: 'metric' | 'imperial';
  /** Display label for law enforcement — drives i18n key resolution */
  officialLabel: string;
  /** BCP 47 locale code */
  defaultLocale: string;
  supportedLocales: string[];
  /** RTL locales — layout will be mirrored */
  rtlLocales: string[];
  privacyPolicyUrl: string;
  termsUrl: string;
}

export const MARKET_CONFIG: MarketConfig = {
  emergencyNumber:  process.env.EMERGENCY_NUMBER   ?? '112',
  policeNumber:     process.env.POLICE_NUMBER       ?? '112',
  fireNumber:       process.env.FIRE_NUMBER         ?? '112',
  emsNumber:        process.env.EMS_NUMBER          ?? '112',
  distanceUnit:    (process.env.DISTANCE_UNIT as 'metric' | 'imperial') ?? 'metric',
  officialLabel:    process.env.OFFICIAL_LABEL      ?? 'Police',
  defaultLocale:    process.env.DEFAULT_LOCALE      ?? 'en',
  supportedLocales: (process.env.SUPPORTED_LOCALES  ?? 'en,fr,es').split(','),
  rtlLocales:       ['ar', 'he', 'fa', 'ur'],
  privacyPolicyUrl: process.env.PRIVACY_POLICY_URL  ?? 'https://geosaveme.app/privacy',
  termsUrl:         process.env.TERMS_URL            ?? 'https://geosaveme.app/terms',
};
