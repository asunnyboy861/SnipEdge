# Pricing Configuration

## Monetization Model: Subscription (IAP) with Consumable Credits

Free download with a functional free tier (3 on-device grades per day), two auto-renewable Pro tiers with a 7-day trial, a consumable analysis-credit pack, and one optional non-consumable offline data pack. BYO API key users get unlimited deep analysis on their own key at no charge.

## Subscription Group
- **Group Name**: SnipEdge Pro
- **Reference Name**: SnipEdge Pro
- **Products in group**: SnipEdge Pro Monthly, SnipEdge Pro Annual

## Subscription Tiers (Auto-Renewable)

### 1. Monthly Subscription
- **Reference Name**: SnipEdge Pro Monthly
- **Product ID**: `com.zzoutuo.snipedge.pro.monthly`
- **Type**: Auto-renewable subscription
- **Price**: $9.99 USD per month
- **Display Name**: `SnipEdge Pro Monthly` (20 chars, ≤35 ✅)
- **Description**: `60 deep chart grades monthly, verified levels` (45 chars, ≤55 ✅)
- **Localization**: English (US)
- **Subscription Group**: SnipEdge Pro
- **Restore Purchases**: ✅ Required

### 2. Yearly Subscription
- **Reference Name**: SnipEdge Pro Annual
- **Product ID**: `com.zzoutuo.snipedge.pro.yearly`
- **Type**: Auto-renewable subscription
- **Price**: $59.99 USD per year (50% savings vs monthly)
- **Display Name**: `SnipEdge Pro Annual` (19 chars, ≤35 ✅)
- **Description**: `90 monthly deep grades, unlimited archive, proof` (49 chars, ≤55 ✅)
- **Localization**: English (US)
- **Subscription Group**: SnipEdge Pro (same group as monthly)
- **Restore Purchases**: ✅ Required

## One-Time Purchases (Non-Consumable)

### 1. Pro Plus Data Pack
- **Reference Name**: SnipEdge Pro Plus Data Pack
- **Product ID**: `com.zzoutuo.snipedge.data.proplus`
- **Type**: Non-consumable (one-time purchase, permanently unlocked)
- **Price**: $14.99 USD (one-time)
- **Display Name**: `Pro Plus Data Pack` (18 chars, ≤35 ✅)
- **Description**: `30+ markets, 5 timeframes of offline win-rate data` (50 chars, ≤55 ✅)
- **Localization**: English (US)
- **Restore Purchases**: ✅ Required
- **Note**: Pure local data expansion — zero ongoing API cost, therefore safe as a one-time purchase.

## Consumable Purchases (Credit Packs)

### 1. 100 Analysis Credits
- **Reference Name**: SnipEdge 100 Credits
- **Product ID**: `com.zzoutuo.snipedge.credits.100`
- **Type**: Consumable
- **Price**: $4.99 USD
- **Display Name**: `100 Analysis Credits` (20 chars, ≤35 ✅)
- **Description**: `100 deep analyses, never expire, stack with any tier` (52 chars, ≤55 ✅)
- **Localization**: English (US)
- **Restore Purchases**: ❌ Not applicable (consumables are not restorable)

## Free Tier (Default)

- **Price**: Free
- **Features**:
  - 3 on-device chart grades per day
  - Teaching "why" explanations when on-device AI is available
  - Archive of the 10 most recent analyses
  - 72-hour outcome grading notifications
  - Watermarked share cards
- **Conversion hooks**:
  - "Deep analysis adds verified levels from real market data — try it once."
  - "Your Proof page needs more graded setups to show your win rate."

## Pro Features Unlocked (All Paid Tiers)

| Feature | Free | Pro (Monthly / Annual) |
|---------|:----:|:----------------------:|
| On-device chart grades | 3 per day | Unlimited |
| Deep vision analysis (official engine) | ❌ | 60 per month (Annual: 90) |
| Verified levels with OHLCV reconciliation | ✅ Limited (latest record only) | ✅ Full history |
| Historical win-rate library | ❌ | ✅ |
| Analysis archive | 10 records | Unlimited |
| Proof page (win rate, average R, streaks) | ✅ | ✅ |
| Hot Streak badge | ✅ | ✅ |
| Share cards | Watermarked | Watermark-free |
| Offline Pro Plus data pack | ❌ Not included — separate $14.99 add-on | Same — purchased separately |

## Free Trial
- **Duration**: 7 days
- **Type**: Free trial (auto-converts to paid subscription)
- **Available for**: SnipEdge Pro Monthly and SnipEdge Pro Annual

## Policy Pages Required
- Support Page: ✅ (must include subscription management + cancellation instructions)
- Privacy Policy: ✅
- Terms of Use (EULA): ✅ (REQUIRED — subscription app)
- **Total policy pages**: 3

## Apple IAP Compliance Checklist
- [x] Auto-renewal terms will be included in Terms of Use
- [x] Cancellation instructions will be included in Support Page
- [x] Pricing clearly stated in PaywallView (period, price, trial length)
- [x] Free trial terms included
- [x] Restore purchases functionality implemented
- [x] No external payment links (Guideline 3.1.1)
- [x] No price references to outside-App-Store options
- [x] All IAP descriptions ≤ 55 characters
- [x] All IAP display names ≤ 35 characters
- [x] BYO API key users are never charged for deep analysis — no generation counting
