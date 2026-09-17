# DHACSS Creek Campus · Flutter prototype

A friendly, contemporary parent/student app concept: deep green, warm ivory, soft mint/lilac cards, generous spacing, Material 3 navigation and reusable components. Built with Flutter, with no third-party runtime dependencies or proprietary image assets.

This is an **interactive, offline demo**, not an official school service. All student identities, fees, marks, messages, routes and announcements are fictional examples. Nothing is submitted to the school, and no payment is processed.

## Included

- Welcome/onboarding and one-tap parent demo entry. No real authentication yet.
- Five destinations: Home, Academics, Services, Messages and Profile.
- Two-child selector; independent homework, payment and chat state per child.
- Home dashboard, sample attendance calendar, weekday timetable and results.
- Homework completion toggles, sample fee invoice and explicit demo payment confirmation/receipt.
- Teacher/office conversations with local-only message composition.
- Leave request form with reason validation, date range picker and local request history.
- Static transport itinerary, notifications and campus information.
- Responsive scrollable layouts, bounded tablet content width, accessible button tooltips.
- Unit/widget tests and GitHub Actions APK build workflow.

## Run locally

Install Flutter **3.35.7** (the CI-pinned SDK) and an Android SDK/emulator or use an Android device with USB debugging. Dart comes with Flutter.

The repository contains the app source. Generate Flutter's standard Android platform files once after cloning; this avoids maintaining hand-written native build scaffolding:

```sh
flutter create --platforms=android --org=pk.edu.dhacss --project-name=dhacss_creek_campus_app --no-pub .
flutter pub get
flutter run
```

The create command preserves existing app source and test files. Do not add `--overwrite`.

For a browser preview, generate the web wrapper too:

```sh
flutter create --platforms=web --project-name=dhacss_creek_campus_app --no-pub .
flutter pub get
flutter run -d chrome
```

## Check and build

```sh
dart format lib test
flutter analyze
flutter test --coverage
flutter build apk --debug
```

APK: `build/app/outputs/flutter-apk/app-debug.apk`.

The debug APK is for device testing only. Before production distribution, configure your approved application ID, app label/icons, release signing, privacy policies and deployment pipeline.

## Get the APK through GitHub

Push the repository to `main`. In **Actions → Flutter checks and Android APK**, open the successful run, then download **creek-campus-prototype-android** under Artifacts. Unzip it and install `app-debug.apk` on your Android phone. Android may ask permission to install from your browser/file manager. Use only the artifact built from your own verified repository.

The workflow can also be started from **Run workflow**. It generates Android scaffolding, resolves dependencies, runs analysis/tests and builds an APK. A workflow file being present does not mean that a build has passed: inspect the actual run result.

## Structure

```text
lib/
  main.dart             Entry point
  src/
    app.dart            Welcome, app shell, dashboard, child selector
    data.dart           Typed sample models and observable session state
    screens.dart        Academic, service, messaging and profile screens
    theme.dart          Material 3 theme and colour tokens
    widgets.dart        Reusable cards, status pills and page layouts
test/
  state_test.dart        Student-state isolation and session tests
  widget_test.dart       Navigation, interactions and viewport smoke tests
.github/workflows/
  android.yml           SDK-pinned checks and debug APK artifact
```

## Prototype boundaries

State is kept in memory and resets after the application restarts. Exiting the demo returns to onboarding without clearing the current session's samples. The partial-month attendance calendar and term attendance percentages are separate illustrative datasets. Timetable content is reused across sample students; results and state are student-specific.

No real sign-in, school API/Odoo integration, secure credential storage, database, push notifications, maps/GPS, file submission or payment gateway is implemented. The app does not request location, contacts, microphone or camera permissions. Official campus logos, photography and approved copy can be supplied later. Campus cards do not claim verified facilities or scheduled events.

## Verification status at creation

Flutter and Dart were not installed in the creation environment, so local analysis, widget tests and APK compilation could not be executed there. Automated checks are provided for the configured GitHub Actions runner; confirm their result before distributing a build. Source was manually reviewed, but it must not be treated as compiler-verified until CI succeeds.

## Next implementation phase

1. Confirm approved campus branding and user journeys.
2. Add secure parent/student authentication and role-scoped APIs.
3. Replace sample repositories with school/Odoo endpoints.
4. Add server-backed attendance, homework attachments, messaging and leave approvals.
5. Integrate a vetted payment gateway with server-side verification and reconciliation.
6. Add verified transport data and opt-in notifications.
7. Perform device/accessibility/security testing and release-sign the app.

Official campus website: https://creekcampus.dhacsskarachi.edu.pk/
