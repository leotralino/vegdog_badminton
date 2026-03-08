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
- `App/AppRootView.swift`: auth-gated root routing
- `App/AppState.swift`: in-memory auth/session state
- `Features/Auth/AuthViewModel.swift` + `Features/Auth/AuthView.swift`: login UI with WeChat code input
- `Features/Sessions/SessionsViewModel.swift` + `Features/Sessions/SessionListView.swift`: session list + join/withdraw/finalize actions
