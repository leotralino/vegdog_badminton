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
