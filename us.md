# SnipEdge: AI Chart Grades — iOS Development Guide

> Source guide: `TR-20260930-图表评级AI-操作指南.MD` (Chinese). This document is the authoritative English engineering specification for the app.

## Executive Summary

**Product vision**: "Snap any trading chart screenshot → get an A–F grade with verified levels, historical win rate, and a trade plan — in 10 seconds."

**Target audience**: Retail traders and chart learners in the US/UK/AU/CA/SG markets — especially small-account day traders, swing traders, and beginners who cannot interpret a chart confidently.

**Core differentiator**: Competitors sell "what the AI says". SnipEdge sells *verifiable evidence*. Every analysis carries:
1. **Price-axis readability gate** — if the Y-axis cannot be read, the app honestly refuses instead of inventing prices.
2. **Real OHLCV reconciliation** — AI-detected levels are checked against actual market data (±1.5%).
3. **Historical win rate** — built-in backtest database keyed by pattern × market × timeframe.
4. **Outcome tracking** — every saved analysis is graded 72 hours later (WIN/LOSS/OPEN), feeding a personal Proof page.
5. **Determinism** — the AI only reports *what it sees* (structured JSON); the grade, stop, and targets are computed by a local deterministic engine.

**Positioning / compliance**: The app is an **Education & Analysis** tool. It never promises profits, never emits "buy/sell guaranteed" signals, and always shows the disclaimer "Educational analysis only. Not financial advice." Primary category: Finance; fallback category: Education.

**Name**: `SnipEdge` — App Store display name: `SnipEdge: AI Chart Grades`. Subtitle: `Snap a chart. Get the grade.`

**Bundle ID**: `com.zzoutuo.SnipEdge` (skill preset `${BUNDLE_PREFIX}SnipEdge`; the guide's `com.yourcompany.snipedge` is intentionally ignored per DOCUMENT-vs-SKILL PRECEDENCE).

**Minimum iOS**: 17.0.

## Competitive Analysis

| App | Strengths | Weaknesses | Our Advantage |
|-----|-----------|------------|---------------|
| ChartDetector AI (150K+ traders, 7 languages) | Strong brand, TikTok-driven acquisition, instant verdict | No verification, no outcome tracking, hard paywall, invented levels | Price-axis gate + OHLCV reconciliation + outcome tracking |
| ChartAI – Stock & Crypto Scanner | Camera capture, RSI/MACD/entry-exit output | Stateless one-shot answers; no consistency or accuracy proof | Deterministic engine + same-image consistency archive |
| CandleScan: AI Chart Analysis | Friendly explanations, dated research links | No grade card, no win-rate data, no proof page | A–F grade card + historical win rate + Proof page |
| Candlytics | Simple snap → trend/pattern/S-R breakdown | Analysis ends when the answer is shown | 72h outcome grading closes the loop |
| Chart Coach | Clear long/short/hold plan, stop included | $7.99/week hard paywall, no free trial | Free 3 grades/day + $9.99/mo (7-day trial) + BYO key unlimited |
| SnapPChart / DayTrade AI | Graded trade plans, unlimited plans | Subscription-only AI budget, no honesty gate | BYO API (zero marginal cost, unlimited) + honest refusal path |
| Trend IQ / ChartingLens | Desktop-grade research, alerts, backtesting | Expensive, heavy, not mobile-first screenshot workflow | Zero-input share-extension flow, 10-second result |

## ⚠️ App Store Compliance — AI Features

### Apple Intelligence (Default Free AI Backend)
The app uses Apple Intelligence (on-device Foundation Models, iOS 26+) as the default free tier backend for quick grading and "why" teaching copy. On supported devices (iPhone 15 Pro and later, iOS 26+), these features work immediately after download with zero configuration.

**iOS version handling**:
- **iOS 26+ with Apple Intelligence available**: free tier works out of the box.
- **iOS 17–25 or Apple Intelligence unavailable**: the free tier degrades to a local heuristic grader (no external model). The UI displays "On-device AI is unavailable on this device — depth analysis is available with your own API key." with a link to Settings → AI Engine.
- **Simulator**: Apple Intelligence is unavailable; a BYO API key must be configured for full testing.

### Official Cloud Engine (GLM Vision)
Deep visual analysis uses the official GLM vision endpoint through the **Cloudflare proxy standard** defined by the `glm-api-config` skill (`cramjam-api.calcs.top`, GLM-5.3-Flash). The real API key lives only in the proxy environment; the client never holds it. Official-engine usage is metered by subscription quota or credit packs.

### BYO API Key (Optional Advanced Configuration)
Users may configure their own key for **GLM / OpenAI / Claude / Gemini / DeepSeek / Custom (OpenAI-compatible)** in Settings → AI Engine. BYO unlocks unlimited deep analysis on the user's own key. Keys are stored in **Keychain only**, never in SwiftData/UserDefaults. A "Test Connection" button issues one minimal request (no user screenshot is attached).

### Guideline 2.1(a) — App Completeness
- Never show clickable AI actions that can only fail.
- When no backend is available, the entry point explains exactly what to enable.
- No free-generation counting logic (`freeGenerationsUsed`, `maxFreeGenerations`, `canGenerateFree`, `incrementGenerationCount()`) is ever used.

## ⚠️ App Store Compliance — Subscriptions

### Guideline 3.1.2(c) — Subscription Information
The Paywall MUST contain:
- Functional Privacy Policy link and Terms of Use (EULA) link.
- Subscription title, length, price per period.
- Auto-renewal disclosure: "Payment will be charged to your Apple ID account at confirmation of purchase. Subscription automatically renews unless it is canceled at least 24 hours before the end of the current period."
- Restore Purchases action.

### Value framing
Subscription value is "Pro tools: verified levels, win-rate library, unlimited archive, Proof page, watermark-free share cards" — never "unlimited AI generations". Official GLM analysis is metered in credits; BYO users are unlimited on their own key.

## Technical Architecture

- **Language**: Swift 5.9+ (Swift 6 compatible patterns avoided for stability)
- **UI**: SwiftUI (primary), PhotosUI, ShareLink, UIKit bridging only where required (Share Extension host)
- **Persistence**: SwiftData (analysis archive, outcomes, user settings cache)
- **Secure storage**: Keychain (`kSecClassGenericPassword`) for BYO keys — one record per provider profile
- **Vision / OCR**: Vision framework (`VNRecognizeTextRequest`) for Y-axis tick extraction and candlestick-density estimation
- **Networking**: URLSession (async/await), JSONDecoder; no third-party networking dependency
- **Charts**: Swift Charts for the equity/proof curve and compact sparklines
- **Purchases**: StoreKit 2 (`Product.products(for:)`, `Transaction.updates` listener, `AppStore.sync()` for restore)
- **Notifications**: UNUserNotificationCenter for the 72h outcome grading push
- **AI**: Apple Foundation Models (iOS 26+, availability-gated) + GLM proxy client + BYO multi-provider client
- **Concurrency**: Swift structured concurrency; all network/analysis work in `Task` with timeouts (8s per LLM call)

## Module Structure

```
SnipEdge/
├── SnipEdgeApp.swift                  // @main, ModelContainer, StoreKit listener bootstrap
├── App/
│   ├── AppEnvironment.swift           // DI container, feature flags, entitlement state
│   └── AppRouter.swift                // top-level route enum (Home / Analysis / Proof / Settings)
├── Models/
│   ├── ChartReading.swift             // AI structured output (what the model saw)
│   ├── VerifiedLevel.swift            // level + price + verified flag + tolerance delta
│   ├── GradeCard.swift                // grade letter, confluence, plan, win rate, verdict
│   ├── GradeRecord.swift              // @Model SwiftData record (hash, card, outcome)
│   ├── Outcome.swift                  // win/loss/open/ambiguous
│   ├── Bar.swift                      // OHLCV bar
│   └── PatternStats.swift             // win-rate library row
├── Services/
│   ├── VisionCaptureService.swift      // image quality gate + axis OCR + candlestick density
│   ├── ImageQualityGate.swift         // blur/size/text-only rejection reasons
│   ├── AxisCalibrationService.swift    // pixel ↔ price linear mapping
│   ├── ChartVisionClient.swift         // protocol + GLM proxy client + BYO dispatcher
│   ├── AppleTutorService.swift         // Foundation Models availability-gated teaching copy
│   ├── MarketDataService.swift         // Yahoo Finance OHLCV fetch + cache
│   ├── ReconciliationService.swift     // ±1.5% level verification
│   ├── ConfluenceEngine.swift          // EMA/RSI/ATR/RVOL + score + grade + plan (pure functions)
│   ├── PatternStatsStore.swift         // bundled SQLite win-rate lookup (sample_size ≥ 30)
│   ├── OutcomeTracker.swift            // WIN/LOSS/OPEN resolution + notification scheduling
│   ├── AnalysisOrchestrator.swift       // end-to-end pipeline: gate → AI → calibrate → verify → grade → persist
│   ├── SubscriptionManager.swift       // StoreKit 2 products, entitlements, credits, restore
│   └── SupportService.swift            // contact support submission (FEEDBACK_BACKEND_URL)
├── ViewModels/
│   ├── AnalysisViewModel.swift
│   ├── GradeCardViewModel.swift
│   ├── ProofViewModel.swift
│   ├── SettingsViewModel.swift
│   └── BYOEngineViewModel.swift
├── Views/
│   ├── Home/HomeView.swift
│   ├── Capture/CaptureImportView.swift
│   ├── Analysis/AnalysisProgressView.swift
│   ├── Analysis/GradeCardView.swift
│   ├── Analysis/WhyDetailView.swift
│   ├── Analysis/RefusalView.swift
│   ├── Proof/ProofView.swift
│   ├── Share/ShareCardRenderer.swift
│   ├── Paywall/PaywallView.swift
│   ├── Settings/SettingsView.swift
│   ├── Settings/BYOEngineView.swift
│   ├── Onboarding/OnboardingView.swift
│   └── Components/ (LevelOverlay, GradeBadge, RiskBar, WinRateRing, DisclaimerBanner, TermChip)
├── Resources/
│   ├── winrate.db                     // bundled offline backtest database
│   └── Assets.xcassets               // app icon, brand colors
└── ShareExtension/                    // share target: receives UIImage → opens analysis
```

## ⚠️ Feature Inventory (MANDATORY — Every Feature Must Be Listed)

### Primary Features

| # | Feature | User Operation Flow | Data Input | Processing | Data Output | Persistence | Acceptance Criteria |
|---|---------|--------------------|------------|------------|-------------|-------------|---------------------|
| 1 | Share-extension capture | 1. User views a chart in any app → 2. taps Share → 3. selects SnipEdge | Shared `UIImage` | Share Extension writes image to App Group inbox; app opens analysis deep link | Analysis flow starts with zero in-app input | App Group container + pending-inbox marker | Share from Photos/Safari/TradingView opens SnipEdge analysis with the same image |
| 2 | In-app capture (Photo library / Camera) | 1. Tap "Grade a chart" → 2. pick photo or capture | `PhotosPickerItem` / camera `UIImage` | Normalize orientation, downscale to max 1440px long edge, JPEG re-encode | Ready-to-analyze image | Not persisted until the analysis is saved | Both paths produce identical downstream results for identical images |
| 3 | Image quality gate | Automatic after image selection | `UIImage` | Blur (Laplacian variance proxy), minimum dimension, candlestick-density check (≥15 consecutive candle-like columns) | Pass or a specific refusal reason | None | Blurry/non-chart images are rejected with a concrete reason, never analyzed |
| 4 | Price-axis OCR gate | Automatic | `UIImage` | Vision OCR on left/right gutter; extract ≥2 numeric Y-axis ticks with consistent spacing; X-axis timeframe hint | Axis calibration model or honest refusal | None | No axis ticks → RefusalView; zero absolute prices are ever emitted |
| 5 | Axis calibration | Automatic | OCR ticks + pixel rows | Linear regression pixel→price; confidence score from fit residual | `AxisCalibration(pixelToPrice, confidence)` | Stored inside the grade record | Calibration confidence < threshold downgrades output to "relative" mode only |
| 6 | Deep visual analysis (GLM) | Automatic when route is cloud | Image + strict JSON-schema prompt | POST to proxy with temperature 0, fixed seed, 8s timeout; JSON Schema validation; 1 retry; fallback to on-device grader | `ChartReading` (chart type, pattern, trend, levels in `y_pixel`, notes) | Raw reading stored in the record | Invalid JSON twice → graceful fallback with credit refund messaging |
| 7 | BYO multi-provider engine | Settings → AI Engine → choose provider → paste key → test → activate | Provider, base URL, key, model, vision flag | Keychain write; one minimal test request; OpenAI-compatible vs Anthropic adapter dispatch | Active profile, connection status | Keychain + UserDefaults (non-secret profile metadata) | All six providers selectable; vision-less profiles are blocked as deep-analysis engines with explanation |
| 8 | OHLCV retrieval | Automatic in cloud path | Symbol guess + timeframe + instrument type | Yahoo Finance chart API, most recent 300 bars, 10s timeout, in-memory cache | `[Bar]` | Cached per symbol+timeframe for the session; bars snapshot kept with record | Fetch failure → analysis still renders but marked "unverified — market data unavailable" |
| 9 | Level reconciliation | Automatic | AI `y_pixel` levels + calibration + real bars | Map pixels→prices, then test ±1.5% against real highs/lows | `VerifiedLevel[]` with `verified` bool + delta | In record | Every displayed price carries a VERIFIED/UNVERIFIED chip |
| 10 | Deterministic confluence grading | Automatic, no AI | Bars + reading trend + verified levels | EMA20/50/200 alignment, RVOL (no look-ahead), Wilder RSI14, ATR14 expansion → weighted 0–1 score | `confluenceScore` | In record | Same inputs always produce the same score (unit-testable purity) |
| 11 | Trade plan generation | Automatic | Entry (nearest verified support), ATR | Stop = entry − 1.5×ATR; TP1 = entry + 1.5R; TP2 = entry + 3R; R:R | Plan numbers + risk bar | In record | Stop/TP always shown together; R:R displayed to 1 decimal |
| 12 | A–F grade computation | Automatic | Confluence score, win rate, R:R, verification state | Letter mapping function with verification penalties | Grade letter + short verdict phrase | In record | A/B only when reconciled; unverified caps grade at C |
| 13 | Historical win-rate lookup | Automatic during grading | Pattern name × timeframe × market | Bundled SQLite query; hides cells with `sample_size < 30` | Win rate + sample size + avg R | Bundled DB (read-only) | Missing/small samples display "Not enough data" instead of a number |
| 14 | Grade Card (hero screen) | Shown after analysis | Record | Renders annotated image with glowing S/R lines, 96pt grade letter, Entry/Stop/TP1/TP2 risk bar, R:R, win-rate ring, VERIFIED badge, disclaimer | Full visual card, shareable | Source record | Disclaimer always visible; unverified levels render amber |
| 15 | Why / teaching expanders | Tap any conclusion chip | `GradeCard` + on-device tutor | Short (≤2 sentence) plain-English explanation, offline-capable, never advisory | Expandable detail rows + glossary chips | Cached per record (optional) | Each conclusion chip is tappable and returns text without network when on-device AI is available |
| 16 | Honest refusal page | Shown on gate failure | Gate failure reason | Explains exactly what is missing + how to retake the screenshot | Refusal UI with retake CTA | None | No grade is produced for refused images |
| 17 | Same-image consistency check | On analysis start | SHA-256 of normalized image | Look up prior record with same hash → show "previous verdict" comparison banner | Comparison strip on result | Record hash index | Same image twice shows the stored prior verdict (no randomness in the deterministic layer) |
| 18 | SwiftData archive | Automatic on save; manual browse in Home list | `GradeCard` + image + bars snapshot | Insert `GradeRecord`; free tier keeps latest 10 | Archive list with filters | SwiftData | Free tier enforced at 10; Pro unlimited |
| 19 | Outcome tracker (72h grading) | Automatic 72h after save | Record + fresh bars | After 72h, compare bars since creation: SL first → LOSS, TP1 first → WIN, same-bar double touch → OPEN, else OPEN | `Outcome` written to record | SwiftData | Outcome appears on record and Proof page; notification fires once |
| 20 | Outcome notification | Automatic at 72h | Pending record | Local notification "Your analysis was graded: WIN ✅ +2.1R" | Banner/notification | Notification scheduled at save time | Notification permission respected; repeated prompts never occur |
| 21 | Proof page | Tap Proof tab | All resolved records | Total win rate, average R, current streak, best streak, per-market breakdown, recent list with WIN/LOSS/OPEN status strip | Dashboard + list | Derived from SwiftData | Numbers match records exactly; empty state explains how to earn proof |
| 22 | Hot Streak badge & share card | 5 consecutive wins | Streak count | Unlock badge; render 1080×1350 card with grade, key levels, watermark | PNG export via ShareLink | Badge state in SwiftData | Pro exports watermark-free; free exports carry "Graded by SnipEdge" |
| 23 | Paywall & subscriptions | Upgrade trigger from quota/limits | StoreKit products | Load products, purchase, verify `Transaction`, entitlement sync, restore | Entitlement + credit balance | StoreKit + local mirror | Monthly $9.99 (7-day trial), Annual $59.99, credits $4.99=100; legal links present |
| 24 | Credit packs (consumable) | Buy from Paywall/Settings | Product ID | Consumable purchase adds 100 credits; credits decrement per official GLM analysis | Balance display | Local mirror reconciled with StoreKit transactions | Credits never go negative; restore does not duplicate consumables |
| 25 | Onboarding (3 screens) | First launch only | None | Demo animation → notification rationale → main screen with 3/3 free grades | Main screen | `hasCompletedOnboarding` | No survey, no paywall in onboarding |
| 26 | Settings | Gear on Home | User choices | Notifications toggle, sound toggle, reduce-motion respect, AI engine entry, policy links, restore purchases, contact support, version display | Settings screen | UserDefaults | Version read from `Bundle.main.infoDictionary` — never hardcoded |
| 27 | Contact support | Settings → Contact Support | Subject preset, message, optional email | Submit to `${FEEDBACK_BACKEND_URL}` via POST; success/error feedback | Confirmation state | None | Preset subject tiles (SF Symbols), required fields, privacy microcopy, graceful failure |
| 28 | Daily free-grade quota | Automatic | Date + device-local counter | 3 on-device grades per calendar day; resets at local midnight | Remaining count display | UserDefaults (device-local) | Quota blocks only the free on-device path, never BYO/Pro paths |
| 29 | Analysis animation & haptics | During analysis | Progress events | 1.2s level-drawing animation, light haptics, optional completion sound, Reduce Motion compliant | Progress screen | None | Animation respects `accessibilityReduceMotion` |
| 30 | Disclaimer surfaces | Home, Analysis, Grade Card, Settings | Static copy | "Educational analysis only. Not financial advice." | Text block | None | Present on all result surfaces and onboarding |

### Sub-Features & Detail Interactions

| # | Parent Feature | Sub-Feature | Detail Description | Interaction Pattern |
|---|---------------|-------------|-------------------|---------------------|
| 3.1 | Image quality gate | Per-reason guidance | Blur / too small / text-only / no candles each produce a distinct message | Static card with retake CTA |
| 4.1 | Axis OCR gate | Tick sanity check | Rejects ticks with inconsistent spacing or reversed order | Auto, silent escalation to refusal |
| 6.1 | Deep visual analysis | Schema retry | First invalid JSON retries once with a "return only JSON" reminder | Automatic |
| 6.2 | Deep visual analysis | Degradation notice | Cloud failure shows "Deep analysis unavailable — fell back to on-device, credit not consumed" | Banner |
| 7.1 | BYO engine | Provider chips | Segmented GLM/OpenAI/Claude/Gemini/DeepSeek/Custom, base URL prefilled, model quick chips | Segmented control + text fields |
| 7.2 | BYO engine | Key display | Shows `••••••1234` (last 4 chars) after save | Read-only field |
| 7.3 | BYO engine | Vision gate | Disabling vision greys out "Use for deep analysis" with explanation | Toggle + inline note |
| 7.4 | BYO engine | Multiple profiles | Save several profiles, activate one, delete with confirmation | List with radio selection |
| 14.1 | Grade Card | Level overlay | Glowing support/resistance lines anchored at calibrated prices; amber when unverified | Static overlay drawing |
| 14.2 | Grade Card | Risk bar | Entry / Stop / TP1 / TP2 three-color horizontal bar with numeric labels | Static |
| 14.3 | Grade Card | Win-rate ring | Circular progress with percentage + sample size | Static |
| 20.1 | Outcome notification | Permission rationale | Second onboarding screen explains 72h grading benefit before requesting | System prompt |
| 21.1 | Proof page | Status strip | Right-edge color strip: green WIN, red LOSS, amber OPEN | Row decoration |
| 21.2 | Proof page | Empty state | Explains proof builds after 72h and links back to capture | Illustration + CTA |
| 23.1 | Paywall | Restore | "Restore Purchases" always visible | Button |
| 25.1 | Onboarding | Free quota display | "3/3 grades left today" large text on final screen | Static |
| 27.1 | Contact support | Backend failure | Shows retry + copy email fallback | Inline error state |

### Cross-Feature Dependencies

| Dependency | Source Feature | Target Feature | Data Passed | Trigger Condition |
|------------|---------------|----------------|-------------|-------------------|
| Capture → analysis | 1/2 | 3 (pipeline) | Normalized image | User completes share or picker |
| Gate → refusal | 3/4 | 16 | Failure reason enum | Gate fails |
| Calibration → reconciliation | 5 | 9 | pixel→price mapping | Gate passes |
| Reconciliation → grade | 9 | 12 | verified flags | Always |
| Stats → grade | 13 | 12 | win rate + sample size | Pattern recognized |
| Grade → archive | 12 | 18 | `GradeCard` + hash | User saves / auto-save |
| Archive → outcome | 18 | 19 | record + createdAt | 72h elapsed |
| Outcome → proof | 19 | 21 | resolved outcome | Outcome resolved |
| Outcome → streak | 19 | 22 | win streak count | 5 consecutive wins |
| Entitlement → quota | 23/24 | 28 | isPro, credits | Every analysis start |
| BYO activation → routing | 7 | 6 | active provider profile | Profile active & vision-capable |
| Onboarding → notifications | 25 | 20 | permission granted | Second screen confirm |
| Analysis → support | 14 | 27 | record id (optional) | User reports an issue |

**⚠️ VERIFICATION CHECK**: 30 primary features, 15 sub-features, 13 cross-feature dependencies documented — matching the Chinese guide's complete feature matrix (§2.2, §4, §5, §8, §9, §12). No guide feature omitted.

## Apple Design Guidelines Compliance

- **Hierarchy & legibility (HIG)**: Dark professional theme, SF Pro for copy, SF Mono for all numeric/trading values; grade letter is the single largest element (96pt).
- **Color**: never color alone conveys state — VERIFIED/UNVERIFIED always pairs color with text and icon.
- **Accessibility**: Dynamic Type support on all text except the decorative grade numeral (which has an accessibility label); Reduce Motion disables line-drawing and particle animations; contrast ≥ 4.5:1 on all data text.
- **Permissions**: notification permission requested only on onboarding screen 2 with a benefit-first rationale; camera/photo permission strings explain purpose.
- **Privacy (Guideline 5.1.1)**: no account required; no personal data transmitted; only the chart image + structured JSON is sent to the analysis endpoint; policy pages linked in Settings and Paywall.
- **Financial app caution (Guideline 3.1.2 / 2.1)**: educational framing, explicit non-advisory disclaimer on every result surface, stop-loss and R:R always shown (risk management over signals).
- **In-app purchase (Guideline 3.1.2)**: StoreKit 2 only for digital content; legal links, price, duration, renewal disclosure, restore.
- **Data minimization**: BYO keys in Keychain; logs redact keys and image payloads.

## ⚠️ Data Flow Diagram (MANDATORY — Every Feature's Data Lifecycle)

```
Feature: Screenshot → Grade Card (end-to-end core loop)
┌───────────────────────────────────────────────────────────────┐
│  User Input                                                    │
│  └── Share sheet (UIImage) / PhotosPicker / Camera             │
│       │                                                        │
│  ViewModel Processing                                          │
│  └── AnalysisViewModel → normalize → ImageQualityGate →         │
│      VisionCaptureService (OCR ticks) → AxisCalibrationService │
│       │                                                        │
│  Considered route                                              │
│  └── BYO active? → BYO client : Pro/credits? → GLM proxy :      │
│      on-device AppleTutorService/heuristic grader              │
│       │                                                        │
│  AI reading                                                    │
│  └── ChartVisionClient → ChartReading (pixels, pattern, trend) │
│       │                                                        │
│  Deterministic layer                                           │
│  └── MarketDataService (bars) → ReconciliationService →         │
│      ConfluenceEngine (score, plan) → grade letter             │
│       │                                                        │
│  Persistence                                                   │
│  └── SwiftData GradeRecord(hash, imageName, card, outcome=nil)  │
│       │                                                        │
│  Display Output                                                │
│  └── GradeCardView (overlay, grade, plan, ring, badge)          │
│       │                                                        │
│  Cross-Feature Output                                          │
│  └── OutcomeTracker schedules 72h job → notification →          │
│      ProofView aggregates → ShareCardRenderer export           │
└───────────────────────────────────────────────────────────────┘

Feature: BYO Engine
┌───────────────────────────────────────────────────────────────┐
│  User Input: provider, base URL, key, model, vision toggle     │
│  ViewModel: BYOEngineViewModel → validation (URL/model)         │
│  Secure store: Keychain item keyed by profile UUID              │
│  Test: single minimal completion request (no image)             │
│  Persist: UserDefaults profile metadata, Keychain secret        │
│  Output: active profile → ChartVisionClient routing             │
└───────────────────────────────────────────────────────────────┘

Feature: Outcome → Proof
┌───────────────────────────────────────────────────────────────┐
│  Scheduler: record.createdAt + 72h (checked at launch/foreground)│
│  Input: stored stop/tp + freshly fetched bars since createdAt   │
│  Process: OutcomeTracker.resolve → win/loss/open/ambiguous      │
│  Persist: GradeRecord.outcome + resolvedAt                      │
│  Display: ProofView stats + record status strip                 │
│  Notify: local notification on first resolution                 │
└───────────────────────────────────────────────────────────────┘

Feature: Subscription & Credits
┌───────────────────────────────────────────────────────────────┐
│  Paywall: SubscriptionManager.products → purchase()             │
│  Verify: StoreKit Transaction verification → entitlement mirror │
│  Credits: consumable purchase → local balance += 100            │
│  Gate: AnalysisOrchestrator checks isPro / credits / BYO        │
│  Restore: AppStore.sync() → rebuild entitlement + non-consumables│
└───────────────────────────────────────────────────────────────┘
```

## Implementation Flow

1. **Project skeleton**: Xcode project (xcodegen), SwiftUI app target, Share Extension target, App Group (sharing pending image), Info.plist usage strings, deep link scheme.
2. **Design system**: `Theme` (colors `#0E1116`, `#22C55E`, `#EF4444`, `#F59E0B`, `#14B8A6`), typography helpers (SF Pro / SF Mono), reusable components (GradeBadge, RiskBar, WinRateRing, DisclaimerBanner, TermChip).
3. **Models & persistence**: `GradeCard`, `ChartReading`, `VerifiedLevel`, `Bar`, `GradeRecord` (@Model), `Outcome`, `PatternStats`.
4. **Vision pipeline**: normalization, `ImageQualityGate`, `VisionCaptureService` (OCR), `AxisCalibrationService`.
5. **Market data**: `MarketDataService` (Yahoo chart API), bar cache, symbol/timeframe inference from OCR.
6. **Deterministic engine**: indicator math (EMA, Wilder RSI, ATR, RVOL) as pure functions; `ConfluenceEngine` score/grade/plan; unit tests for determinism.
7. **Reconciliation**: `ReconciliationService` ±1.5%, verification flags.
8. **Win-rate library**: bundled `winrate.db`, `PatternStatsStore` with sample-size guard; graceful "not enough data".
9. **AI clients**: `ChartVisionClient` protocol; GLM proxy client (strict prompt, JSON schema validation, retry, timeout); BYO dispatcher (OpenAI-compatible + Anthropic adapter); `AppleTutorService` availability-gated.
10. **Orchestrator**: `AnalysisOrchestrator` wires gate → AI → calibration → bars → reconcile → grade → persist → schedule outcome; emits progress events for animation.
11. **UI**: Home, Capture, Analysis progress (animated line drawing), Grade Card, Why expanders, Refusal page, Proof page, Share card renderer, Onboarding, Settings, BYO engine, Paywall.
12. **Monetization**: StoreKit 2 subscription manager, consumable credits, restore, entitlement gating, quota.
13. **Notifications**: 72h outcome scheduling + permission rationale.
14. **Compliance**: disclaimers everywhere, policy links, disclaimer in share card, privacy strings.
15. **Build, test, polish**: iPhone + iPad builds, dark mode, Dynamic Type, Reduce Motion, empty states.

## UI/UX Design Specifications

- **Theme**: Deep charcoal `#0E1116` background with elevated surfaces `#161B22`; data colors: up `#22C55E`, down `#EF4444`, warning `#F59E0B`, brand teal `#14B8A6`.
- **Typography**: SF Pro for prose; SF Mono (monospaced digits) for every price, percentage, R:R and grade letter.
- **Grade Card layout**: upper half = chart image with level overlay; lower half = 96pt grade letter + verdict, risk bar (Entry/Stop/TP1/TP2), R:R highlight `1:2.8`, win-rate ring, VERIFIED badge; footer disclaimer.
- **Proof page**: hero win-rate number, average R, streak flame, status strips, Swift Charts equity curve.
- **Motion**: 1.2s level-drawing during analysis; restrained win particle effect; haptics; all gated by Reduce Motion.
- **Empty/error states**: every screen has an explicit empty state and a concrete error state with a next action.
- **Localization-ready**: all user-facing strings in English, `Localizable`-friendly structure.

## Code Generation Rules

- One feature per module; high cohesion, low coupling.
- Deterministic engine and AI clients are strictly separated; no AI call may bypass `ConfluenceEngine`.
- Every displayed price must carry a verification flag; unverified prices are never rendered as confirmed.
- Comments only where logic is non-obvious; no decorative comments.
- Apple-native frameworks only (SwiftUI, SwiftData, Vision, StoreKit 2, Foundation Models when available).
- No hardcoded version strings — read from Bundle.
- No free-generation counters; gating is `isPro || credits > 0 || byoActive || freeQuotaRemaining > 0` for the free on-device path only.

## Build & Deployment Checklist

- [ ] xcodegen project builds for iPhone and iPad simulators with zero warnings-as-errors blockers.
- [ ] Share Extension appears in the share sheet and hands the image to the app.
- [ ] Gate, OCR, calibration, reconciliation, grading produce consistent results for the same image.
- [ ] Grade Card renders overlay, plan, ring, badge, disclaimer.
- [ ] Outcome tracker resolves after the 72h threshold (test with a compressed interval in debug).
- [ ] Proof page aggregates correctly; empty state present.
- [ ] StoreKit configuration file used for local purchase testing; restore works.
- [ ] BYO engine: all six providers selectable; test connection success/failure states; key masked.
- [ ] Notification permission rationale and scheduling verified.
- [ ] Policy links (support, privacy, terms) resolve after PHASE 7 deployment.
- [ ] Disclaimer visible on Home, Analysis, Grade Card, Settings.
- [ ] Dark theme, Dynamic Type, Reduce Motion verified.
