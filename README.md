# wajz-mobile

Flutter app for **Wajz (واجِز)** — a calm, trust-first, source-grounded daily news briefing.

## Entry points

- Consumer mobile/web app: `flutter run -t lib/main.dart`
- Admin web dashboard: `flutter run -d chrome -t lib/main_admin.dart`

The admin dashboard is a separate web entry point. Its visible controls reflect
roles, but all `/admin/*` authorization is enforced by the FastAPI backend.

> Stay informed in minutes. No noise. Sources included.

## What it does

- **Onboarding** — language, topics, regions, briefing length, explanation level.
- **Today** — a finite daily briefing with a progress indicator that ends in
  *"You are caught up."* No infinite feed.
- **Explore** — controlled browsing by category.
- **Story detail** — what happened, why it matters, key facts, what is still
  unclear, source comparison, and links to every original source.
- **Saved** — read-later list with optimistic save/unsave.
- **Profile** — all preferences plus sign-out.
- Calm design system: Inter, deep navy/muted teal, generous spacing, full
  dark-mode support, no red-alert design and no dopamine mechanics.

## Stack

Flutter · Riverpod (state) · GoRouter (navigation) · Dio (API) ·
flutter_secure_storage (token) · shared_preferences (local flags).

The app **never calls AI APIs directly** — it only talks to
[`wajz-backend`](../wajz-backend), which owns all keys and processing.

## Running

Start the backend first (see its README), then:

```bash
flutter pub get

# Android emulator (backend on host machine):
flutter run

# Web browser (backend on the same machine):
flutter run -d chrome

# Physical device / custom host:
flutter run --dart-define=WAJZ_API_BASE=http://192.168.1.10:8000
```

The default API base is `http://10.0.2.2:8000` on Android and
`http://127.0.0.1:8000` on web. Override either with `WAJZ_API_BASE`.

Build release artifacts with:

```bash
flutter build apk
flutter build web
```

Auth in this MVP uses the backend's dev-login: the app creates a stable
per-device account automatically. Swap `SessionController.ensureSignedIn` for
Firebase/Supabase sign-in when moving past the MVP.

## Tests & lints

```bash
flutter analyze
flutter test
```

## Structure

```
lib/
  core/        api client, models, theme, storage, shared providers
  features/    splash, onboarding, briefing (Today), stories, explore,
               saved, profile, preferences
  widgets/     StoryCard, ConfidenceBadge, CategoryChip, BriefingProgress,
               SaveButton, SourceComparisonRow, StorySection, PreferenceChip,
               Empty/Loading/Error states, AppShell (bottom nav)
  router.dart  GoRouter config (4-tab shell + onboarding + story detail)
```
