# Student Record Management App (CSE101 Final Project)

A Flutter app that turns a simple list of students into a **complete digital
class record**: sections, student profiles, scores per category, one-tap
attendance and a teacher-friendly dashboard.

All data is **simulated with plain `List` / `Map` objects and hardcoded sample
records in memory** - no Hive, Firebase, SQLite, Firestore, Supabase, MySQL or
any NoSQL database is used.

## Features

| # | Feature | Where |
|---|---------|-------|
| 1 | Section-based setup: pick a section first, create new sections, new students are added to the selected section | `screens/section_list_screen.dart`, `screens/section_form_screen.dart` |
| 2 | Student profile: picture, student ID, full name, age, gender, section, contact | `models/student.dart`, `screens/student_form_screen.dart` |
| 3 | Grades: Quiz 1/2/3, Exam, Activity, Assignment, Project + new categories, score and total per category | `models/score.dart`, `screens/score_form_screen.dart` |
| 4 | One-tap attendance: PRESENT -> ABSENT -> EXCUSED -> PRESENT, with date recording | `Student.cycleAttendance()`, `widgets/status_chip.dart` |
| 5 | Student list per section: search, picture, name, status, quick view, edit, delete | `screens/student_list_screen.dart` |
| 6 | Teacher dashboard: students, present, absent, excused, class average | `SectionStats` in `data/record_manager.dart` |
| 7 | Records per student: picture, grades, quizzes, exams, attendance history, overall average, class rank | `screens/student_detail_screen.dart` |
| 8 | Class records summary (printable style) | `screens/records_screen.dart` |

## Widgets used

Text, Icon, Image (`Image.network` with initials fallback), Container, Card,
Button (FilledButton / OutlinedButton / TextButton / IconButton / FAB),
TextField (`TextFormField` inside a `Form`), AppBar, Chip, Dialog, ListTile,
CircularProgressIndicator, LinearProgressIndicator, Tooltip.

## Layout widgets used

Column, Row, Wrap, ListView (+ `ListView.builder`), GridView, Expanded,
Flexible, Stack, Padding, SizedBox, LayoutBuilder, SingleChildScrollView-free
scroll views, TabBar / TabBarView.

## Responsive design

* Home screen uses a `GridView` that switches between 1 / 2 / 3 columns
  depending on the screen width.
* The student list switches to a `GridView` (cards) on wide screens and keeps a
  `ListView` on phones.
* The dashboard tiles use a `Wrap` with a computed tile width (2 / 3 / 5 per
  row).
* Text widgets that sit next to a `Spacer` are wrapped in `Expanded` with
  ellipsis so nothing overflows on small phones.
* Verified with widget tests at 320x640, 420x1000 and 1000x700.

## Project structure

```
lib/
  main.dart                  app entry, theme, initial route
  app_routes.dart            page navigation table (named routes)
  data/
    record_manager.dart      in-memory store (List only) + dashboard stats
    sample_data.dart         hardcoded sample sections/students/scores
  models/
    student.dart             student + averages + attendance logic
    section.dart             section, programs, year levels
    score.dart               categories and score entries
    attendance.dart          attendance status + date helpers
  screens/                   7 screens
  theme/app_theme.dart       Material 3 theme
  widgets/                   avatar, status chip, stat card, empty state
test/widget_test.dart        20 unit + widget tests
```

## How to run

```bash
flutter pub get
flutter run                 # phone or emulator
```

## Run it in the browser / install it as an app

The project ships as a **PWA** (Progressive Web App), so the same build runs in
any browser and can be installed as a standalone app on a computer or a phone.

Build the release the same way GitHub Pages serves it:

```bash
powershell -ExecutionPolicy Bypass -File tool/build_web.ps1
```

`tool/build_web.ps1` passes `--base-href "/<repo-name>/"` so the output also
works from a GitHub Pages sub-path. Use `-RepoName` if the repository is not
named after this folder.

Serve it on `localhost` (a service worker and the install prompt need `localhost`
or HTTPS, so opening the file directly will not work):

```bash
node tool/serve_web.js       # then open http://localhost:8080
```

### Installing it

| Platform | Steps |
|----------|-------|
| Chrome / Edge (Windows, Mac, Linux, Android) | An **Install** bar appears at the bottom of the app, or use the browser's install icon in the address bar. |
| iPhone / iPad (Safari) | **Share** -> **Add to Home Screen**. An in-app hint appears after a few seconds. |

Once installed the app opens in its own window with no browser UI, and it keeps
working offline because `web/sw.js` caches the app shell.

### Deploying to GitHub Pages

`.github/workflows/deploy-pages.yml` builds and publishes the site on every push
to `main`:

1. Create a repository on GitHub and push this project to it.
2. Go to **Settings -> Pages**, set **Source** to **GitHub Actions**.
3. Push to `main` and wait for the `Deploy to GitHub Pages` workflow to finish.
4. The app is live at `https://<user>.github.io/<repo>/`.

## How to test

```bash
flutter analyze             # static analysis, should report no issues
flutter test                # 20 tests
```

## How to build the APK

```bash
flutter build apk --debug   # build/app/outputs/flutter-apk/app-debug.apk
flutter build apk --release # build/app/outputs/flutter-apk/app-release.apk
```

## Screenshots to submit

Take screenshots of: (1) home / section list, (2) student list with dashboard
and one-tap attendance, (3) add/edit student form with validation, (4) student
record with grades / attendance / profile tabs, (5) class records summary.
