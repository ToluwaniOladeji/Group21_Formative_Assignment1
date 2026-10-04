# Beacon - Project & SLA Task Tracker

Flutter app for a small software team. Tracks tasks, deadlines and SLA health (On track / At risk / Overdue / Completed).

## First-time setup (everyone, once)
```bash
git clone <repo-url> && cd beacon_tracker
flutter create . --platforms=android,ios   # generates android/ios folders, does NOT touch lib/
flutter pub get
flutter run                                # run on an emulator or a phone, NOT Chrome
flutter test                               # SLA unit tests
```

## Who owns what
| Member | Branch | Screens / files |
|---|---|---|
| **A** Foundation & Data | `feature/data-sla` | `models/*`, `services/*` (database, prefs, SLA), `test/`, `sla_rules_screen`, `activity_screen` |
| **B** Navigation & People | `feature/nav-people` | `app_shell`, `sign_in_screen`, `team_screen`, `profile_screen`, `workload_screen` |
| **C** Tasks CRUD | `feature/task-list-form` | `task_list_screen`, `task_form_screen`, `attention_screen`, `utils/validators.dart` |
| **D** Dashboard & Design | `feature/dashboard-details` | `dashboard_screen`, `task_details_screen`, `utils/theme.dart`, `widgets/*`, README |

Every screen file starts with a doc comment listing its TODOs. Placeholder screens use `PlaceholderScreen`; replace it with your real UI.
Need a change in someone else's file (e.g. a new DB method)? Ask them, or make a small separate PR.

## Storage decision
- **SQLite (sqflite)**: tasks, members, activity log. Relational (task -> assignee), needs sorting and counting.
- **SharedPreferences**: signed-in member id and the editable SLA thresholds. Small key/value settings.

## SLA rules (`services/sla_service.dart`)
1. Done -> **Completed**
2. Deadline passed -> **Overdue**
3. Blocked -> **At risk**
4. Time left <= risk window -> **At risk** (High 72h, Medium 48h, Low 24h; +24h if still To do)
5. Otherwise -> **On track**

Thresholds are editable in-app (SLA rules screen) and persist in SharedPreferences.

## Design tokens (`utils/theme.dart`)
Never hard-code colours, sizes or fonts in a screen. Use `AppColors`, `AppSpacing`, `AppRadius` and `Theme.of(context).textTheme`.
Fonts: Plus Jakarta Sans (headings), Inter (body) via `google_fonts` (needs internet on first run, then cached).
Signature element: the coloured SLA edge on every `TaskCard`.

## Git rules
- Never push to `main`. Branch -> commit small -> open PR -> a teammate reviews -> merge.
- Commit messages: `Add title validation to task form`, not `update`.
- Merge `main` into your branch daily: `git pull origin main`.
- Log your work in the contribution tracker as you go.

## Data flow (for the demo)
Screen `initState()` -> `DatabaseService` (async) -> `setState()` -> UI rebuilds.
After `Navigator.push` returns, the caller re-runs `_load()` so lists show fresh data.
