# AGENTS.md

This repo is designed for fast collaboration between product owner and Codex.

## Source of Truth
- Product requirements: `docs/SPECS.md`
- API contracts: `backend/openapi/openapi.yaml`
- iOS app scaffold: `app/ios/`

## Working Rules
- Keep scope incremental. Land core flows first: login, queue (接龙), payment links.
- Match feature changes with spec updates in the same PR.
- Prefer small, testable commits.
- When requirements are ambiguous, document assumptions in `docs/SPECS.md` under "Open Questions".

## Coding Direction
- iOS app target: Swift + SwiftUI.
- Backend: TBD (can start with BaaS or custom API based on team preference).
- Localization: Chinese-first UI copy, English-friendly code naming.

## Delivery Phases
1. MVP: WeChat login + queue creation/join/withdraw + payment method sharing.
2. V1: settlement assistance + notifications + basic history.
3. Add-on: match organization and score tracking.
