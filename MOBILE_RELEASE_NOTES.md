# DHACSS Connect 0.3.0 — connected school features

## Included source and deployed database

- Parent login, persistent session, linked children, campus filter and student search.
- Student account access using school-managed `student_accounts` links; no self-enrollment.
- Five-tab student workspace: Home, Academics, Services, Updates, Profile.
- Live attendance with monthly counts; staff can enter or correct an attendance day.
- Class homework, due dates and instructions; assigned teachers/admins can create, edit and delete.
- Monthly bills from the admin portal, including original amounts, due dates, void reasons and copyable bill details.
- Class/campus timetable, exam schedules, notices, events, transport routes and document information; campus admins publish and maintain entries through the mobile app.
- Student results with subject marks, percentage and remarks; staff entry/corrections.
- Leave submission and history; assigned staff approve/reject; requester may cancel pending requests. Decisions cannot be overwritten.
- Student conversation shared between linked family, student account and assigned staff. This is a school/family thread, not private messaging between two individuals.
- Loading, empty, retry and refresh states. The live app never falls back to demo records.
- Isolated authenticated navigation, so signing out disposes the student screens.

## Setup and operator steps

Existing project `myflhqgvdahmxyridpcb` has `monthly_fee_generation` and `connected_mobile_school_features` applied. Do not reapply these to that project.

For a new empty database apply `backend/schema.sql`, `portal.sql`, `status_year.sql`, `monthly_fees.sql`, then `mobile_features.sql`. Grant staff memberships using a trusted administrator. Student logins must already exist in Auth. An authorized admin can use **Link student login** in the mobile dashboard to connect the account UUID to the correct student.

1. Sign in with a school administrator/teacher/parent account.
2. Search/select a student and tap **Open school services**.
3. Staff use **Add record** within the authorized module. Campus publications default to the selected class; an admin may explicitly select the whole campus.
4. Parents/students see published records, apply for leave, and write messages. Pull down or tap Refresh for updates.
5. Generate bills in the existing Angular portal's **Monthly fees** screen; they appear in the student's mobile Fees screen.

Timetable, transport and document entries are school-published information. This release does not include automatic timetable generation, GPS, attachment storage or PDF report-card generation.

## External integrations still required

- Online payments: choose the school's merchant/gateway account, configure server-side checkout and verified webhooks, and implement payment reconciliation. No app button marks a bill paid.
- Push notifications: supply a school-owned Firebase project and Android/iOS app configuration, device-token registration, notification permissions and a trusted sender. The Updates tab currently shows in-app notices only.
- Live bus tracking: supply an authorized vehicle GPS feed and route assignments; this release shows published routes/stops only.
- Production distribution: school-owned Android signing key and store account; iOS requires Apple signing and a macOS build.
- Admission applications, complaints, certificate requests, downloadable challan/report-card PDFs and document attachments are not included in this release.

## Validation

Database integration tests in `backend/mobile_features_test.sql` passed on the hosted project using temporary fixtures with transaction rollback. Coverage includes class/campus isolation, student account visibility, results, family messages, leave review and rejection of parent self-approval. `backend/monthly_fees_test.sql` covers fee generation. All test data was rolled back.

Dart formatting parsed the changed Dart sources successfully. Flutter analysis, widget tests and the Android APK build were NOT completed: automatic approval review rejected Flutter execution because its environment detector attempted to access the link-local cloud metadata service. A subsequent CI-mode attempt was also rejected, and no further build attempts were made. No new APK is included. The existing APK predates these changes.

The prepared GitHub workflow runs Flutter analysis, all widget tests, database tests, and an Android debug APK build. Publishing these changes and running that workflow requires approval following the earlier GitHub upload rejection. Do not treat the mobile source as a validated release until these checks pass.

Supabase's security advisor reports no table/RLS warnings for these additions. It reports an existing Auth setting: leaked-password protection disabled. Configure according to the project's available Auth plan: https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection
