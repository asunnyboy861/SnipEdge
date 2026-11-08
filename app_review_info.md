# App Review Information — SnipEdge: AI Chart Grades

## Overview
SnipEdge is an **educational chart analysis tool**. Users share a chart screenshot and receive an A–F grade, verified support/resistance levels, a trade plan, and historical win-rate context. The app never places trades, never connects to a broker, and never promises profit. Every result surface displays: "Educational analysis only. Not financial advice."

## Reviewer Walkthrough (no account required)

1. Launch the app and read the 3 onboarding screens.
2. Tap **Grade a chart from Photos** and choose any candlestick chart screenshot with a visible right-side price axis.
3. The app reads the price axis, checks the detected levels against real market data, and shows the Grade Card.
4. A chart without a readable price axis intentionally returns the honest refusal screen — that is a designed feature, not an error.
5. Open **Proof** to see outcome tracking; open **Settings** for AI engine, notifications, legal links, and Contact Support.

Free tier: 3 on-device grades per day, no key and no subscription required. Pro adds deep vision analysis with verified levels.

## Subscription Testing
- Group: **SnipEdge Pro**
- Monthly: `com.zzoutuo.snipedge.pro.monthly` — $9.99/month, 7-day free trial
- Annual: `com.zzoutuo.snipedge.pro.yearly` — $59.99/year, 7-day free trial
- Consumable: `com.zzoutuo.snipedge.credits.100` — $4.99 for 100 deep analyses
- Non-consumable: `com.zzoutuo.snipedge.data.proplus` — $14.99 Pro Plus data pack
- Restore Purchases is available in Settings and on the Paywall.

## AI Engine (Bring Your Own API Key)
The app ships with a working free tier that requires no API key. Optional deep analysis with the user's own key is configured in:
**Settings → AI engine → Provider → Base URL → Model → API key → Test connection → Save profile**.

- Keys are stored only in the device Keychain (`kSecClassGenericPassword`), never in UserDefaults or files.
- The app does **not** sell API keys, does not bundle any provider key in user-visible form, and does not gate AI usage by generation counters.
- Any OpenAI-compatible endpoint or Anthropic endpoint works. Provider display labels are generic ("GPT", "GLM", "Claude", "Gemini", "DeepSeek", "Custom").
- If Apple Intelligence is available on the reviewer's device (iOS 26+, iPhone 15 Pro or later), on-device teaching explanations work without any key.

## Required Links (in-app)
- Privacy Policy: https://asunnyboy861.github.io/SnipEdge/privacy.html
- Terms of Use: https://asunnyboy861.github.io/SnipEdge/terms.html
- Support: https://asunnyboy861.github.io/SnipEdge/support.html
- Contact Support inside the app posts to a feedback endpoint and requires no account.

## Review Notes

### Financial / Educational Framing
- Category positioning: Education & Analysis (Finance as primary category).
- No "buy/sell signals", no profit claims, no auto-trading, no broker connection.
- Risk is always shown with the reward: Stop, Entry, TP1, TP2, and R:R appear together.
- Disclaimer is present on onboarding, home, grade card, share card, and settings.

### AI Features (BYO Key Model)
- AI is optional. Free on-device grading works immediately after download with no configuration.
- Users may add their own API key; the app never resells AI capacity.
- No generation counting, no free-usage caps on AI, no dead code such as `freeGenerationsUsed`.
- Cloud analysis may be routed through a proxy that meters credits by subscription; the proxy never stores the chart image beyond the request.

### China App Store Compliance
This app does not include ChatGPT functionality and does not reference ChatGPT in user-facing UI or metadata. The optional AI engine uses a generic "Bring Your Own API Key" model where users configure their own endpoint. No specific AI provider is bundled or promoted.

### HealthKit / WeatherKit
Not used. No health data, no weather data, no location data.

### Notifications
Local notifications only (72-hour outcome grading). Permission is requested on onboarding screen 2 with a benefit-first rationale, and can be disabled in Settings.

### Data & Privacy
- No account, no analytics SDK, no advertising SDK.
- Chart screenshots are processed on-device; only the image is sent to the analysis endpoint when the user chooses cloud analysis.
- Analysis history is stored locally with SwiftData; images are stored in the app's Documents directory.
