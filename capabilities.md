# Capabilities Configuration

## Analysis
Detected requirements from the operation guide and `us.md`:
- "share / 分享截图" → **Share Extension target** (zero-input capture from any app)
- "存档 / SwiftData" + "分享扩展传图" → **App Groups** (share pending image between extension and app)
- "通知 / 判分推送 / notification" → **Local notifications** (UNUserNotificationCenter, 72h outcome grading)
- "相机 / 拍照 / 照片 / screenshot" → **Camera + Photo Library usage strings**
- "订阅 / 会员 / premium / 次数包" → **In-App Purchase** (StoreKit 2 — configured in code; products created in App Store Connect)
- Network access to endpoint (HTTPS, no ATS exception needed)

## Auto-Configured Capabilities
| Capability | Status | Method |
|------------|--------|--------|
| Share Extension target (`SnipEdgeShare`) | ✅ Configured | xcodegen `project.yml` — `app-extension`, `NSExtensionPointIdentifier: com.apple.share-services`, image activation rule |
| App Group (app + extension) | ✅ Configured in project | Entitlements `group.com.zzoutuo.SnipEdge` in both targets |
| Local notifications | ✅ Configured in project | UNUserNotificationCenter at runtime; permission rationale in onboarding (no entitlement required) |
| Camera / Photo Library permissions | ✅ Configured | `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription` in Info.plist |
| Deep link scheme | ✅ Configured | `snipedge://` URL scheme in Info.plist |
| Privacy manifest | ✅ Configured | `SnipEdge/PrivacyInfo.xcprivacy` (UserDefaults CA92.1 + FileTimestamp C617.1) and `SnipEdgeShare/PrivacyInfo.xcprivacy` (UserDefaults CA92.1) |
| Export compliance | ✅ Configured | `ITSAppUsesNonExemptEncryption = false` |
| Development team | ✅ Configured | `DEVELOPMENT_TEAM = JP4TN5PTS3` at project level (inherited by every target) |

## Manual Configuration Required
| Capability | Status | Steps |
|------------|--------|-------|
| App Group provisioning | ⏳ Pending (signing) | Sign in to Xcode with the Apple ID, then run: `xcodebuild -project SnipEdge.xcodeproj -scheme SnipEdge -destination 'generic/platform=iOS' -allowProvisioningUpdates build` — Xcode auto-registers `group.com.zzoutuo.SnipEdge` on the portal and regenerates profiles |
| In-App Purchase products | ⏳ Pending (ASC) | Create subscription group + products in App Store Connect (IDs documented in `price.md`) |
| Official GLM proxy registration | ⏳ Auto-handled by code phase | `glm-api-config` registers the Bundle ID in the worker whitelist and injects the dev key into a gitignored local secret file |

## No Configuration Needed
- iCloud / CloudKit — not required (all data is local SwiftData)
- Apple Watch — not required
- HealthKit / Location / Siri — not required
- Push Notifications (remote APNs) — not required; local notifications only
- Background Modes — not required (outcome check runs on launch/foreground)

## Verification
- Build succeeded after configuration (iPhone 16 simulator): ✅
- All entitlements correct: ✅ (App Group key present in both targets)
- Signing verification (generic/platform=iOS): ⏳ DEFERRED — provisioning profile lacks the App Groups capability (`group.com.zzoutuo.SnipEdge`). Per skill policy, no portal-side workaround was attempted; the user signs in to Xcode and runs the `-allowProvisioningUpdates` command above.
- DEVELOPMENT_TEAM: JP4TN5PTS3 (project-level, inherited by app + extension)
- PrivacyInfo.xcprivacy: App target + Share Extension target
