# VegDog Badminton

[中文文档](./README.zh-CN.md)

<p align="center">
  <img src="./app/ios/Resources/Brand/vegdog_logo.png" alt="VegDog Logo" width="160" />
</p>

VegDog (`菜狗`) is an iOS-first app for badminton friend groups to run queue signups (接龙), manage late-withdraw logic, and share payment links.

## Tech Stack
- iOS: Swift 5.10, SwiftUI, MVVM, async/await
- API layer: OpenAPI 3.0.3 contract at `backend/openapi/openapi.yaml`
- Project generation: XcodeGen (`app/ios/project.yml`)
- Current runtime mode: mock service by default (`USE_MOCK_SERVICE=true`)
- Localization: English + Simplified Chinese (`en.lproj`, `zh-Hans.lproj`)

## Product Roadmap
- MVP
  - WeChat login
  - Session create/join/withdraw/finalize queue flow
  - Payment method sharing and payment status tracking
- V1
  - Settlement assistance
  - Notifications
  - Basic session/payment history
- Add-on
  - Match organization
  - Score tracking and basic stats

## Repo Structure
- `docs/SPECS.md`: product requirements and milestone baseline
- `backend/openapi/openapi.yaml`: API contract source of truth
- `app/ios/`: iOS app code and resources
- `app/ios/Resources/Brand/`: logo assets (`vegdog_logo.png`, `vegdog_logo.svg`)
- `AGENTS.md`: collaboration and implementation rules

## Quick Start (iOS)
1. Install `xcodegen`:
   - `brew install xcodegen`
2. Generate project:
   - `./app/ios/scripts/generate_xcodeproj.sh`
3. Open project:
   - `./app/ios/scripts/open_in_xcode.sh`

## Localization
- App languages supported:
  - English (`en`)
  - Simplified Chinese (`zh-Hans`)
- The in-app language toggle is available in the top-right toolbar.

## Documentation
- English: `README.md` (this file)
- Chinese: `README.zh-CN.md`
- Detailed product specs: `docs/SPECS.md`
