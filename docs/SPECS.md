# SPECS.md

App Name:
- English: VegDog (Vegetable Dog)
- Chinese: 菜狗

## 1. Product Vision
Build an iOS app for badminton friends to organize sessions with queue sign-up (接龙), payment collection, and optional match tracking.

## 2. Core Roles
- Initiator: any verified member can create sessions. Initiator name is visible on session list/detail.
- Session Admin: initiator is default session admin; session admins can add other session admins.
- Participant: joins or withdraws from sessions, pays organizer.

## 3. MVP Features

### 3.1 Authentication
- Login with WeChat.
- Basic profile: nickname, avatar, WeChat OpenID/UnionID mapping.

### 3.1.1 Localization
- Supported languages (only):
  - English
  - Mandarin Chinese (Simplified)
- App branding by locale:
  - English: VegDog (Vegetable Dog)
  - Chinese: 菜狗

### 3.2 Queue / 接龙
- Any member creates a session with:
  - title
  - date/time
  - location
  - number of courts
  - max participants
  - withdraw deadline
  - fee rule (fixed per person or split by attendance)
- Participants join queue.
- If max is exceeded, extra users are marked as waitlist (后补).
- Participants can withdraw before deadline freely.
- If a participant withdraws after deadline, status becomes `late_withdraw`.
- The roster is finalized when admin submits the final namelist to the badminton court (`finalize_at`).
- Late-withdraw payment rules:
  - If no replacement fills the spot by `finalize_at`, the `late_withdraw` participant still owes the base court fee.
  - If a replacement fills the spot by `finalize_at`, the `late_withdraw` participant is exempt from base court fee, and the replacement participant pays instead.
  - If final attendee count is lower than `max participants` at `finalize_at`, unpaid empty spots are split across liable participants using the session fee rule.
- Extra usage metadata:
  - Participant flag `stayed_late` indicates extra court usage (for example, extra hour after scheduled end).
- Session admin sets this flag manually.
  - Participants with `stayed_late` owe an additional fee defined by session settlement rules.
- Session admin permissions:
  - finalize roster (`finalize_at`)
  - mark participant `stayed_late`
  - add other session admins
- MVP queue UI behavior:
  - Tab layout: `Queue`, `History`, `Settings`
  - Queue detail shows session meta (time/location/admin)
  - Participant list is vertical with clear split:
    - within `max participants`
    - waitlist / standby
  - One user can create multiple queue entries (for friends)
    - first default name: own nickname
    - repeated joins default to `nickname +N`
  - Entry removal is per-entry via `-` action on entries created by the current user
  - Withdrawn entries appear in a bottom withdrawn panel
  - Rejoin with same entry name removes it from withdrawn panel
  - Queue lock behavior:
    - when locked, no new join and no withdrawal
    - admin can mark `stayed_late` using checkbox-style control
    - late-play marking appears once queue is locked (enabled after start time)


### 3.3 Payment
- Admin (or designated collector) can configure payment methods:
  - Venmo handle / deep link
  - Zelle contact
  - Other free-text method
- Participants can tap payment method entry to launch supported app link when possible.
- App tracks payment status:
  - `unpaid`
  - `paid`
  - `waived`
- MVP information architecture note:
  - Payment configuration lives under `Settings` tab instead of a standalone `Payments` tab.

### 3.4 User Profile Metadata (MVP Optional)
- Fields in settings:
  - avatar URL
  - nickname
  - gender (optional)
  - level (optional)
- Queue display:
  - avatar shown left of participant name
  - gender/level metadata shown when available

## 4. Add-on Features (Phase 2)

### 4.1 Match Organization
- Build match groupings for active attendees.
- Record scores per game.
- Basic stats:
  - wins/losses
  - point differential
  - recent results

## 5. State Model (MVP)

### 5.1 Session Status
- `draft`
- `open`
- `locked` (after withdraw deadline)
- `completed`
- `canceled`

### 5.2 Participant Status
- `joined`
- `waitlist`
- `withdrawn`
- `late_withdraw`

## 6. Suggested Data Entities
- `User`
- `Session`
- `SessionParticipant`
- `PaymentMethod`
- `PaymentRecord`

See API draft: `backend/openapi/openapi.yaml`.

## 7. Technical Direction
- iOS: SwiftUI, async/await, MVVM.
- Backend options:
  - Option A: Firebase/Supabase + WeChat auth bridge.
  - Option B: custom backend (e.g., FastAPI/Node) + SQL DB.

Recommended for speed: start with Option A unless custom compliance requirements appear.

## 8. Milestones
1. Wireframes + UX flow validation
2. iOS app shell + login flow stubs
3. Queue full lifecycle
4. Payment methods + payment tracking
5. Match module add-on

## 9. Open Questions
- Do we need automatic cost split per attendee count/court/time?
- Should late withdrawal liability be full fee only, or configurable ratio (for example 50%)?
- Is push notification needed for waitlist promotion and deadlines?
