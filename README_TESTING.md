# Activity 15 — automated verification patch

This patch preserves the existing trivia UI and behavior. It adds an optional request override to `TriviaScreen` so Flutter widget tests can simulate a delayed API response, HTTP failure/retry, API-level failure, single-answer scoring, full-round progression, and replay without depending on live network access.

Copy `lib/main.dart` and `test/widget_test.dart` into the corresponding folders of your existing local Activity15 project. Then run:

```bash
flutter pub get
flutter test
flutter analyze
git add lib/main.dart test/widget_test.dart
git commit -m "Add automated tests for trivia loading, errors, scoring and replay"
git push
```

**Do not claim these tests passed until `flutter test` actually reports success.** The original screenshots remain the observed Chrome evidence. These automated tests are additional, reproducible evidence.
