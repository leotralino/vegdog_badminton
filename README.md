# VegDog Badminton

<p align="center">
  <img src="./app/ios/Resources/Brand/vegdog_logo.png" alt="VegDog Logo" width="160" />
</p>

<p align="center">
  <b><a href="./README.md">English</a></b> | <a href="./README.zh-CN.md">中文</a>
</p>

VegDog (`菜狗`) is an iOS-first app for badminton friend groups to run queue signups (接龙), manage late-withdraw logic, and share payment links.

<p align="center">
  <img src="https://img.shields.io/badge/iOS-17.0+-0A84FF.svg" alt="iOS 17+">
  <img src="https://img.shields.io/badge/Swift-5.10-F05138.svg?logo=swift&logoColor=white" alt="Swift 5.10">
  <img src="https://img.shields.io/badge/UI-SwiftUI-0A84FF.svg" alt="SwiftUI">
  <img src="https://img.shields.io/badge/architecture-MVVM-34C759.svg" alt="MVVM">
  <img src="https://img.shields.io/badge/API-OpenAPI%203.0.3-6E56CF.svg" alt="OpenAPI 3.0.3">
  <img src="https://img.shields.io/badge/project-XcodeGen-111111.svg" alt="XcodeGen">
  <img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="MIT License">
</p>

## Tech Stack
- iOS client: Swift 5.10, SwiftUI, MVVM, async/await
- API contract: OpenAPI 3.0.3 at `backend/openapi/openapi.yaml`
- Project generation: XcodeGen from `app/ios/project.yml`
- Runtime mode: mock service by default (`USE_MOCK_SERVICE=true`)
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
