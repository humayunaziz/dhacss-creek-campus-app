# DHACSS Connect 0.4.0 visual update

The connected Flutter app now follows the shared DHACSS mobile references:
navy text, teal-to-blue campus banners, light blue page background, pastel
shortcuts, rounded cards, DHACSS crest branding, and a five-tab bottom bar.

Updated surfaces include sign-in, the connected student home, academic/service
lists, the offline parent demo, and the campus preview. The home screen links
attendance, timetable, homework, fees, results, transport, leave and messages;
exam schedules and school announcements remain connected to their existing
records. The Creek Campus photo is bundled as `assets/campus-reference.jpg`.

Preview images are in `assets/theme-preview-login.png` and
`assets/theme-preview-connected-home.png`. They are visual previews only and
are not loaded by the Flutter runtime. The theme implementation is in
`lib/src/theme.dart`, `brand.dart`, `live_app.dart`, `student_workspace.dart`,
`app.dart`, `widgets.dart` and `screens.dart`.

The prior visual pass reported 25 app/widget and data-isolation checks passing.
This package has been checked for required assets and source completeness, but
Flutter is not available in this workspace, so this packaging pass did not
rerun Flutter analysis or produce a 0.4.0 APK. Build and test from this source
with a Flutter 3.35.7 installation before distributing an updated APK.
