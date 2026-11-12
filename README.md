# In-Class Activity 15: API-to-Cloud Trivia Showdown

**Student:** Akshitha Sainath Sanagarapu  
**Student ID:** 003027780  
**Course:** CSC 4360 – Mobile App Development  
**Due:** November 11, 2026, 11:59 PM EST

## Overview
This Flutter trivia app retrieves five easy, multiple-choice general-knowledge questions from the Open Trivia Database REST API. It decodes JSON, cleans HTML entities, shuffles answers, shows loading/error states, highlights correct answers green and incorrect selections red, prevents duplicate scoring, displays the final score, and supports replay.

## Running the project
1. Install Flutter and confirm `flutter doctor` is working.
2. The repository already includes Android and web platform configuration.
3. Run `flutter pub get`.
4. Run `flutter run -d chrome` (or select an Android emulator).
5. For an Android APK, run `flutter build apk --release` and find it at `build/app/outputs/flutter-apk/app-release.apk`.

For Android, verify `android/app/src/main/AndroidManifest.xml` contains `<uses-permission android:name="android.permission.INTERNET" />` as a child of `<manifest>` (outside `<application>`). A patch script is included to insert it automatically after `flutter create .`.

## REST API
`GET https://opentdb.com/api.php?amount=5&category=9&difficulty=easy&type=multiple`

The app checks HTTP status 200 and JSON `response_code == 0`, requires five results, maps JSON into a Dart question model, and decodes HTML entities using `html_unescape`.

## Score submission
The final screen offers **Simulate Score Sync**. It constructs a payload containing activity name, score, total question count, and timestamp, prints it to debug logs, and simulates a one-second asynchronous submission. **This is not a real POST request and does not save data to a cloud backend.** A real leaderboard requires an instructor-provided endpoint and confirmation response.

## Observed app results
I ran the app in Chrome and completed a full five-question round. The question screen displayed four options, the progress bar advanced, incorrect answers were shown in red with the correct answer in green, and correct answers increased the score. My final score was **2/5**. I selected **Simulate Score Sync**, and the screen displayed **Simulation complete** with the message that no real cloud write occurred. The screenshots in `screenshots/` show these results.

## API bridge debrief
A GET request reads existing question resources; the app checks both HTTP and API-level results before updating UI. A real leaderboard would use a POST request with a JSON score payload, await the server response, and display success only if the backend accepted the write. The included simulation practices the UI flow without claiming remote persistence.

## Graduate critical-thinking responses (Activity 15 update)

### 1. Restart and offline experience

In my trivia app, I used the Open Trivia Database API to fetch five questions. Once the questions are loaded, I can answer them without making another API request. If the internet disconnects during the round, I can still continue with the questions that are already loaded. For restarting, I added a Play Again button that starts a fresh round by fetching new questions. If the internet is unavailable during that request, the app displays an error with an option to retry.

For offline support in the future, I would consider saving the current questions and score locally so users could continue after closing the app. I would clearly distinguish saved questions from newly fetched questions and check that the saved data is complete before allowing the user to resume. Compared with keeping an unlimited cache of old questions, this would make it easier to tell whether a round is current. A useful test would be to close the app after answering two questions, reopen it without internet, and check whether the saved progress is restored correctly. Local saving is a design idea for future work, not part of this version.

### 2. Local score history versus a shared leaderboard

In my app, I display the score as I answer each question. I tested both correct and incorrect answers: the score increased for correct answers and stayed the same for incorrect answers. After completing five questions, my final score was 2/5. I also clicked Simulate Score Sync and saw “Simulation complete.” That action demonstrates the submission flow, but it does not upload anything to a cloud database.

If I added score history later, I would save completed scores on the device and label the screen “My Score History (this device).” I would keep it separate from a shared leaderboard, because local records are not visible to other users. Local history would be easier to build and work offline, but it would not sync between devices. A real leaderboard would require a backend that accepts and confirms scores. I would test the difference by checking two devices: a score stored only on one should not appear on the other or be described as cloud synced. I kept this version focused on the required trivia round and the clearly labeled sync simulation.

## Engineering evaluation and evidence

**Request and validation:** The app issues a GET request to Open Trivia Database and separately checks the HTTP response and API-level `response_code`. A successful HTTP transport response alone does not guarantee usable questions. The parsed JSON is converted into question objects before display; entity decoding and answer shuffling prepare the data for the UI.

**State and failure boundary:** The screen distinguishes loading, a usable question round, and a visible error with retry. Answer selection is guarded so a second tap cannot add another point. A missing connection or invalid API payload must not be displayed as a completed fetch.

**Submission boundary:** The score action builds a payload and waits asynchronously but does not send a POST request. A successful simulation confirms only that the local UI completed its demonstration, not that a leaderboard stored the score.

**Observed evidence:** I completed the round in Chrome and captured the question display, incorrect and correct feedback, question progression, score updates, the final 2/5 result, and the score-sync simulation confirmation.

### Screenshot evidence
1. `screenshots/01_question_loaded.png` — Question 1 of 5 with four options.
2. `screenshots/02_incorrect_feedback.png` — Incorrect selection in red and correct option in green.
3. `screenshots/03_question_progression.png` — Question 2 of 5 after advancing.
4. `screenshots/04_correct_feedback.png` — Correct answer highlighted and score increased to 1.
5. `screenshots/05_score_update.png` — Score increased to 2 on Question 3.
6. `screenshots/06_round_complete.png` — Completed five-question round with score 2/5.
7. `screenshots/07_simulation_complete.png` — Simulation complete, explicitly without a cloud write.

## Automated verification (November 11, 2026)

After adding the widget tests, I ran `flutter pub get`, `flutter test`, and `flutter analyze` on my Mac. Flutter reported **4 tests passed** and **No issues found**. The automated checks exercise the loading state, HTTP failure and retry, API-level failure, single-answer scoring, round completion, and replay. These test results supplement the seven Chrome screenshots; they are not screenshots of those additional scenarios.

To reproduce the checks, run:

```bash
flutter pub get
flutter test
flutter analyze
```

The tests use controlled responses so error and loading cases can be evaluated without relying on live network availability. The score-sync action remains a simulation, not a backend write.
