# iOS App Scaffold

This folder contains starter structure for the iOS app.

## Recommended Stack
- SwiftUI
- MVVM
- URLSession + Codable

## Suggested Project Modules
- `App`: app entry and navigation
- `Features/Auth`: WeChat login flow
- `Features/Sessions`: queue creation/join/withdraw
- `Features/Payments`: payment method display and status updates
- `Features/Matches`: score tracking (phase 2)
- `Core`: shared models, networking, utilities

## Next Step
Create Xcode project named `BadmintonFriends` and map source groups to this folder layout.

## Implemented Core Scaffold
- `Core/Models/APIModels.swift`: Codable models aligned with `backend/openapi/openapi.yaml`
- `Core/Networking/APIEndpoint.swift`: endpoint path + method mapping
- `Core/Networking/APIClient.swift`: async request layer with auth token support
- `Core/Networking/BadmintonService.swift`: typed service methods for feature modules
- `Core/Utils/AppEnvironment.swift`: API base URL config (`API_BASE_URL` override)

## Implemented Feature Scaffold
- `App/BadmintonFriendsApp.swift`: SwiftUI app entry
- `App/AppRootView.swift`: auth-gated root routing + tab shell
- `App/AppState.swift`: in-memory auth/session state
- `Features/Auth/AuthViewModel.swift` + `Features/Auth/AuthView.swift`: login UI with WeChat code input
- `Features/Sessions/SessionsViewModel.swift` + `Features/Sessions/SessionListView.swift`: session list + create/join/withdraw/finalize actions
- `Features/Sessions/SessionCreateViewModel.swift` + `Features/Sessions/SessionCreateView.swift`: admin create-session form
- `Features/Sessions/SessionDetailViewModel.swift` + `Features/Sessions/SessionDetailView.swift`: session detail + initiator/admin display + add-admin + participant `stayed_late` admin update
- `Features/Payments/PaymentsViewModel.swift` + `Features/Payments/PaymentsView.swift`: payment methods + records management UI by session ID

## Xcode Project Generation
This repo uses XcodeGen so project files stay reproducible.

### Prerequisites
- Full Xcode installed (not only Command Line Tools)
- `xcodegen` installed

```bash
brew install xcodegen
```

### Generate Project
Run from repo root:

```bash
./app/ios/scripts/generate_xcodeproj.sh
```

This creates:
- `app/ios/BadmintonFriends.xcodeproj`

### Open in Xcode

```bash
./app/ios/scripts/open_in_xcode.sh
```

### Notes
- If code signing fails, set your team in Xcode target settings.
- API base URL defaults to `https://api.example.com`.
- Override API base URL at runtime with env var: `API_BASE_URL`.
- Local development uses mock service by default (`USE_MOCK_SERVICE=true`).
- To force real API mode, run with env var `USE_MOCK_SERVICE=false`.
