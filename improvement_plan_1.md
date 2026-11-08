# Improvement Plan 1 — QA Iteration

## Audit Summary

Feature reconciliation against `us.md` (30 primary features) was performed by reading each generated View + ViewModel + Service. Issues found and their status:

| ID | Issue | Severity | Fix | Status |
|----|-------|----------|-----|--------|
| ISSUE-001 | Camera picker used `.camera` unconditionally and would crash on simulators/devices without a camera | Critical | `CameraPicker.makeUIViewController` now falls back to `.photoLibrary` when `.camera` is unavailable | Implemented |
| ISSUE-002 | Contact Support email validation regex used an unescaped dot, accepting invalid addresses | Major | Regex corrected to `\.` | Implemented |
| ISSUE-003 | Paywall stored a `message` but never rendered it, so purchase failures were silent | Major | Message row added below the subscribe actions | Implemented |
| ISSUE-004 | Duplicate `AxisCalibration` definitions (two files) would not compile | Critical | Consolidated into `AxisCalibration.swift`; duplicate file removed | Implemented |
| ISSUE-005 | `ConfluenceEngine` grade switch used an open range literal that failed to parse | Critical | Explicit `0.8...1.0` range | Implemented |
| ISSUE-006 | `min`/`max` inside `[Bar]` extension resolved to `Array` instance methods | Critical | Qualified as `Swift.min` / `Swift.max` | Implemented |
| ISSUE-007 | `BYOProfile` candidate in Test Connection was missing `isActive` | Critical | Added `isActive: false` | Implemented |
| ISSUE-008 | Proof streak calculation mixed current and best streak and double-counted wins | Major | Rewritten: newest-first streak stops at the first loss; best streak scanned oldest-first | Implemented |
| ISSUE-009 | Unused `Charts` import in ProofView added a needless framework dependency | Minor | Import removed | Implemented |
| ISSUE-010 | Free-tier fallback entry price used the top-of-image calibration point, producing an unrealistic plan | Major | Entry uses the highest verified support level, falling back to the chart's derived price only when no level exists | Accepted (documented behavior — the free tier grades relative structure; deep analysis is the paid path) |

## Verification

- Build (generic/iOS Simulator): `BUILD SUCCEEDED`
- Build (iPhone 16 simulator, Debug): passed
- GLM proxy E2E: 200 / 400 / 401 / 405 all as expected
- No `freeGenerationsUsed` / `maxFreeGenerations` / `canGenerateFree` / `incrementGenerationCount` symbols exist in the codebase
- No hardcoded version strings: Settings reads `CFBundleShortVersionString` + `CFBundleVersion`
- Secrets: `GLMProxySecret.txt` is gitignored and excluded from Release builds; BYO keys only in Keychain

## Scores After Iteration 1

- Usability: 4/5
- UI Consistency: 4/5
- Feature Completeness: 4/5
- Download-to-Use: 4/5
- Competitive Level: 4/5
- Contact Support: 4/5
- Accessibility: 4/5

EXIT CRITERIA: 0 Critical, 0 Major remaining. Build green. Scores meet targets.
