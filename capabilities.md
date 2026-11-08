# SnipEdge — 配置文档

生成时间：2026-11-08

---

## 一、⚠️ 手动配置（增强功能 — 不配置不影响基本使用）

> **重要说明**：以下配置项不完成时，App 的核心评级流程、免费 3 次/天、存档、Proof 页、分享卡、联系客服均可正常使用。配置后可解锁订阅购买、App Group 分享扩展签名与上架审核流程。

### 🟡 App Group 签名（Share Extension 跨 App 传图）

**增强功能**：从任意 App 分享截图时，图片可直接经 App Group 交给主 App 分析。
**不配置的影响**：主 App 内从相册/相机选图仍完全可用；分享扩展在真机签名前无法安装。
**当前状态**：entitlements 已写入两个 target；模拟器可用，真机需签名。

**已自动配置部分**：
- ✅ `project.yml` 已声明 App target + Share Extension target
- ✅ 两个 target 的 entitlements 均包含 `group.com.zzoutuo.SnipEdge`
- ✅ Share Extension 的 Info.plist 已配置 `com.apple.share-services` 与图片激活规则
- ✅ 代码已实现降级：分享不可用时，主 App 相册导入不受影响

**如需启用，请手动完成**：
1. 打开 Xcode，用你的 Apple ID 登录（Xcode → Settings → Accounts）。
2. 打开 `SnipEdge.xcodeproj`，在 Signing & Capabilities 中确认两个 target 的 Team 为 `JP4TN5PTS3`。
3. 在终端执行：
   `xcodebuild -project SnipEdge.xcodeproj -scheme SnipEdge -destination 'generic/platform=iOS' -allowProvisioningUpdates build`
4. Xcode 会自动在开发者后台注册 `group.com.zzoutuo.SnipEdge` 并重建描述文件。
5. 真机安装后用任意 App 分享一张图表截图到 SnipEdge 验证。

---

### 🔵 IAP StoreKit 配置（订阅与次数包）

**影响功能**：不在 App Store Connect 创建产品，用户无法购买 Pro 或次数包；免费层不受影响。

**配置步骤**：
1. 打开 [App Store Connect](https://appstoreconnect.apple.com) → 你的 App → **Monetization** → **Subscriptions**。
2. 新建订阅组：Reference Name `SnipEdge Pro`，Group Name `SnipEdge Pro`。
3. 在组内创建两个自动续期订阅：

| 产品 | Reference Name | Product ID | 价格 | 试用 |
|------|---------------|-----------|------|------|
| 月付 | SnipEdge Pro Monthly | `com.zzoutuo.snipedge.pro.monthly` | $9.99 / 月 | 7 天免费试用 |
| 年付 | SnipEdge Pro Annual | `com.zzoutuo.snipedge.pro.yearly` | $59.99 / 年 | 7 天免费试用 |

4. 在 **Monetization** → **In-App Purchases** 创建两个非订阅产品：

| 产品 | Reference Name | Product ID | 类型 | 价格 |
|------|---------------|-----------|------|------|
| 100 Analysis Credits | SnipEdge 100 Credits | `com.zzoutuo.snipedge.credits.100` | Consumable | $4.99 |
| Pro Plus Data Pack | SnipEdge Pro Plus Data Pack | `com.zzoutuo.snipedge.data.proplus` | Non-Consumable | $14.99 |

5. Display Name / Description 直接复制 `price.md` 中的对应字段（均已校验 ≤35 / ≤55 字符）。
6. 每个订阅需上传审核截图（可在模拟器用 Xcode 的 StoreKit Configuration 测试后截图）。
7. 产品状态变为 **Ready to Submit** 后，随 App 版本一起提交审核。
8. 在 App 内 Settings → Subscription → **Restore Purchases** 验证恢复流程。

---

### 🟢 App Store Connect 审核信息

**影响功能**：不填写审核备注，审核员可能无法理解 BYO Key 与订阅逻辑，触发 Guideline 2.1(a) 询问。

**配置步骤**：
1. App Store Connect → 你的 App → **App Review Information**。
2. **Notes** 字段粘贴 `app_review_info.md` 中的 “Review Notes” 全部内容。
3. **Demo Account** 留空即可：App 无需登录，免费层开箱可用。
4. **Privacy Policy URL** 填 `https://asunnyboy861.github.io/SnipEdge/privacy.html`。
5. 确认 App 内 Paywall 与 Settings 中的隐私政策、服务条款、支持页链接均可打开（已部署并验证 200）。

---

## 二、✅ 自动配置记录（已由系统完成，无需操作）

### Capabilities 自动配置

| Capability | 说明 | 状态 |
|------------|------|------|
| App Groups | 主 App 与分享扩展共享 `group.com.zzoutuo.SnipEdge` | ✅ 已配置（entitlements） |
| Share Extension | `SnipEdgeShare` target，图片分享激活规则 | ✅ 已配置 |
| 本地通知 | 72 小时判分提醒，无需 entitlement | ✅ 已配置（代码） |
| 相机 / 相册 | `NSCameraUsageDescription`、`NSPhotoLibraryUsageDescription` | ✅ 已配置 |
| In-App Purchase | StoreKit 2 客户端代码与产品 ID | ✅ 已配置（代码）；ASC 产品见 Section 一 |
| Deep link | `snipedge://` URL scheme | ✅ 已配置 |
| 出口合规 | `ITSAppUsesNonExemptEncryption = false` | ✅ 已配置 |
| 隐私清单 | 两个 target 的 `PrivacyInfo.xcprivacy` | ✅ 已配置 |

### 后端服务

| 服务 | 说明 | 状态 |
|------|------|------|
| 联系客服后端 | `https://msg.calcs.top/api/feedback`，POST JSON 五个必填字段 | ✅ 已部署 |
| GLM 官方代理 | `https://cramjam-api.calcs.top`，appId `snipedge` 已注册白名单 | ✅ 已注册（E2E 200/400/401/405 通过） |
| 行情数据 | Yahoo Finance chart API（公开、无 Key） | ✅ 已接入 |
| HTTPS 出站 | 默认允许，无需 ATS 例外 | ✅ 已配置 |

### 代码与生成物

| 模块 | 说明 | 状态 |
|------|------|------|
| 核心功能 | MVVM：看图 → 轴门禁 → AI/启发式读图 → 对账 → 确定性评级 → 存档 → 72h 判分 | ✅ 已完成 |
| AI 引擎 | BYO 多服务商（GLM/GPT/Claude/Gemini/DeepSeek/Custom）+ 官方 GLM 代理 + 端侧启发式 | ✅ 已完成 |
| ContactSupportView | 7 个主题磁贴 + 名称/邮箱/内容 + 后端对接 + 成功/失败反馈 | ✅ 已完成 |
| SettingsView | Pro 状态、AI 引擎、通知、隐私/条款/支持、版本号、免责声明 | ✅ 已完成 |
| PurchaseManager | StoreKit 2 订阅、消耗型积分、恢复购买、响应式 isPro | ✅ 已完成 |
| App 图标 | Agnes 生成的青绿 K 线 + 裁切角图标，1024 RGB 无 alpha | ✅ 已完成 |
| QA 迭代 | `improvement_plan_1.md`，10 项问题修复 | ✅ 已完成 |

### 部署

| 项目 | 说明 | 状态 |
|------|------|------|
| GitHub 仓库 | https://github.com/asunnyboy861/SnipEdge | ✅ 已完成 |
| GitHub Pages | 政策页 + Landing Page 已上线（4 个 URL 均 200） | ✅ 已完成 |
| Landing Page | `https://asunnyboy861.github.io/SnipEdge/`（App Store ID 为占位符） | ✅ 已完成 |
| App Store 元数据 | `keytext.md` 已通过 19 项校验 | ✅ 已完成 |
| 定价配置 | `price.md` 已生成并校验字符限制 | ✅ 已完成 |

### 💡 使用提示（用户 App 内操作，非开发者配置）

**AI 深度分析**：免费层无需任何 Key。用户如需不限次深度分析，可在 **Settings → AI engine** 选择服务商、填入自己的 Key、测试连接并保存。Key 只存本机 Keychain。这是用户操作，不是开发配置步骤。

---

## 三、能力检测详情

### Analysis

基于指南与 `us.md` 检测到的需求关键词：
- “分享截图 / share” → Share Extension target（零输入捕获）
- “存档 / SwiftData” + “分享扩展传图” → App Groups
- “通知 / 判分推送” → 本地通知（UNUserNotificationCenter）
- “相机 / 照片 / 截图” → Camera + Photo Library usage strings
- “订阅 / 会员 / 次数包” → In-App Purchase（StoreKit 2）
- 网络：HTTPS 出站（Yahoo Finance、GLM 代理、反馈后端）

### No Configuration Needed

- iCloud / CloudKit — 不需要（全部数据本地 SwiftData）
- Apple Watch — 不需要
- HealthKit / Location / Siri — 不需要
- 远程推送 APNs — 不需要（仅本地通知）
- Background Modes — 不需要（判分在启动/前台检查）

### Verification

- 模拟器构建（iPhone 17 / iPad Pro 13-inch）：✅ BUILD SUCCEEDED
- 运行冒烟：✅ Onboarding 与 Home 正常渲染
- App Group entitlements：✅ 两个 target 均已写入
- 真机签名：⏳ 待用户登录 Xcode 后执行 Section 一 中的 `-allowProvisioningUpdates` 命令
- 隐私清单：✅ App + Share Extension 均覆盖
- GLM 代理 E2E：✅ 200 / 400 / 401 / 405
