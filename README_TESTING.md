# Activity 15 — Testing and verification

## Verification results

On November 11, 2026, I ran the following commands in the Flutter project on my Mac:

```bash
flutter pub get
flutter test
flutter analyze
```

**Observed terminal results:**
- `00:03 +4: All tests passed!`
- `No issues found! (ran in 0.8s)`

The four automated widget tests cover loading, HTTP failure and retry, API-level failure, duplicate-answer scoring protection, completing the round, and replay. The tests use controlled API responses to make these cases repeatable.

## Manual evidence

Seven screenshots in `screenshots/` document a Chrome five-question round, red/green answer feedback, score progression to 2/5, the completed round, and the simulated score-sync confirmation. Loading/error/replay screenshots were not separately captured; automated tests provide additional verification.

## Scope

The score action simulates asynchronous submission. It does **not** POST to a cloud service or persist a shared leaderboard. Local storage is discussed in the graduate design answers but is not implemented.

## Reproduce

From the project root, run:

```bash
flutter pub get
flutter test
flutter analyze
```
