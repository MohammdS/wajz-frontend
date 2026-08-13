# Wajz consumer client

Flutter mobile and web client for Wajz (واجِز).

The consumer is guest-first. Explore and public story reading do not require
an account. Sign-in or sign-up is optional and unlocks account-scoped
preferences, saved stories, and personal briefings.

## Local development

```powershell
flutter pub get
flutter run
flutter run -d chrome
```

Defaults:

- Android emulator API: `http://10.0.2.2:8000`
- Web API: `http://127.0.0.1:8000`
- Production authentication: disabled unless its two Supabase defines exist
- Development login: disabled unless `WAJZ_ENABLE_DEV_LOGIN=true`

Enable local development login explicitly:

```powershell
flutter run --dart-define=WAJZ_ENABLE_DEV_LOGIN=true
```

Configure optional production authentication:

```powershell
flutter run `
  --dart-define=WAJZ_API_BASE=https://api.example.com `
  --dart-define=WAJZ_SUPABASE_URL=https://project.supabase.co `
  --dart-define=WAJZ_SUPABASE_PUBLISHABLE_KEY=...
```

The sign-in screen supports email/password, sign-up, password reset, and
Google OAuth. Android/iOS OAuth returns to
`io.wajz.app://login-callback/`. Add equivalent authorized redirect URLs in
Supabase and configure the Google provider there.

All account-scoped Riverpod state is invalidated on sign-in, sign-out, token
restoration, and account switching, preventing one account's saved stories,
briefing, or preferences from appearing in another session.

## Release builds

Android release builds fail unless a real signing configuration exists. Copy
`android/key.properties.example` to ignored `android/key.properties`, point it
to a protected keystore, and build:

```powershell
flutter build appbundle --release `
  --dart-define=WAJZ_API_BASE=https://api.example.com `
  --dart-define=WAJZ_SUPABASE_URL=https://project.supabase.co `
  --dart-define=WAJZ_SUPABASE_PUBLISHABLE_KEY=...
```

Build the consumer web client:

```powershell
flutter build web --release
```

The release workflow builds the consumer web client, creates a signed Android
App Bundle, and attaches both artifacts to a version-tag release. Configure
repository environment `production` with:

- Secrets: `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`,
  `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`
- Variables: `WAJZ_API_BASE`, `WAJZ_SUPABASE_URL`,
  `WAJZ_SUPABASE_PUBLISHABLE_KEY`, `WAJZ_AUTH_REDIRECT_URL`

Extract the web artifact and use `deployment/Caddyfile` with
`deployment/.env.web.example` to serve it over automatically managed HTTPS.

## Validation

```powershell
flutter analyze
flutter test
flutter build web --release
```

The clients never receive or call AI provider keys. Gemini, translation,
ingestion, and all other AI operations remain in the backend queue.
