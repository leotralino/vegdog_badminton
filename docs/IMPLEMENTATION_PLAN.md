# Implementation Plan

## Phase 0: Foundation
- Finalize `docs/SPECS.md` open questions.
- Create Xcode project and CI baseline.
- Define backend choice (BaaS vs custom API).

## Phase 1: MVP
- WeChat login.
- Session CRUD (admin).
- Join/waitlist/withdraw logic with deadline enforcement.
- Roster finalization flow (`finalize_at`) to lock replacement decisions.
- Settlement logic for late withdraw:
  - no replacement by `finalize_at` => late withdraw still liable
  - replacement by `finalize_at` => replacement participant liable
  - underfilled session handling based on fee rule
- Participant metadata flow (`stayed_late`) for extra usage fee.
- Payment method config and participant payment status.

## Phase 2: Match Add-on
- Match grouping.
- Score entry UI.
- Simple player stats.

## Non-Goals (MVP)
- Ranking system
- Tournament bracket automation
- Multi-club tenancy
