# DHACSS Connect — connected mobile school app

See `MOBILE_RELEASE_NOTES.md` for the 0.3.0 feature list, operator steps and remaining integrations.

## First hosted setup

1. Create a free Supabase project under your own organization. No domain is required;
   Supabase supplies the HTTPS database/API endpoint. Free quotas and inactivity policies apply.
2. Apply `backend/schema.sql` **once to a new project** using the Supabase SQL editor.
   Do not run the disposable test harness against a hosted project.
3. In Authentication settings, disable public signup for this school-managed pilot.
   Create confirmed test accounts through Authentication → Users. Use test data first.
4. Copy the intended head-office account UUID, then run this trusted bootstrap SQL:

   ```sql
   insert into public.staff_memberships(user_id, campus_id, role)
   values ('HEAD_OFFICE_AUTH_USER_UUID', null, 'head_office');
   ```

5. Sign in as head office and create the campus. Assign a campus administrator using
   the SQL editor with a verified account UUID and the correct campus UUID:

   ```sql
   insert into public.staff_memberships(user_id, campus_id, role)
   values ('CAMPUS_ADMIN_AUTH_USER_UUID', 'CAMPUS_UUID', 'campus_admin');
   ```

6. Sign in as that administrator, add a student, then use **Link parent** with the
   existing parent's Authentication UUID. Verify the parent's identity before linking.
   Sign in as the parent to see that child. Password resets/account provisioning are
   managed through Supabase for this milestone; self-service invitations come later.

Staff memberships cannot be edited by the app. Row-level security in PostgreSQL
restricts parents to linked students and campus administrators to assigned campuses.
The SQL test suite attempts cross-campus reads/writes, escalation and anonymous access.

## Run or build

Use Flutter 3.35.7 (Dart 3.9). Generate platform wrappers once:

```sh
flutter create --platforms=android,web --org=pk.edu.dhacss --project-name=dhacss_creek_campus_app --no-pub .
flutter pub get
flutter run --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

Use the **publishable key only**, never a secret/service-role key. These defines are
embedded in the client and are public; database access relies on Auth and RLS.
Without both values the build explicitly offers the offline demo, with no live login.

```sh
flutter analyze
flutter test
flutter build apk --debug --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
flutter build web --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

The generated web folder can be deployed to Cloudflare Pages using its provided
`pages.dev` address. Hosting is not configured by committing this code. Android
release distribution still requires signing and a persistent Internet permission
in the release platform manifest; the current CI APK is a debug test build.

## Automated checks and deliverables

GitHub Actions runs Flutter analysis and tests, builds Android and web, and tests
SQL isolation in a disposable PostgreSQL database. It uploads the APK, web build,
coverage and resolved dependency lockfile. The Supabase package is pinned exactly;
the CI-resolved `pubspec.lock` is committed for reproducible dependency resolution.
CI builds with `--dart-define-from-file=config/supabase.json`, which contains only
the project's public URL and publishable client key. No privileged key belongs there.
The hosted project is `dhacss-connect` in `Dhacss Education Dte` (Singapore).
Its initial schema is deployed and the hosted SQL access-control tests pass.
Initial account provisioning and dashboard Auth settings still require setup;
the web portal build is not yet publicly hosted. To run against this backend:

```sh
flutter run --dart-define-from-file=config/supabase.json
```

This is the first backend milestone, not a production-complete school system.
Verify the hosted Auth/Data API configuration and access rules with separate parent,
campus-admin and head-office accounts before adding real student information.

The first dashboard uses single-page API reads (subject to the project's response-row
limit). It is suitable for a small pilot; add pagination/search before loading full
campus rosters. Staff creation and linking are available; editing, transfer, account recovery UI, and revoking links from the UI are future work. A trusted
administrator can revoke a link in the Supabase dashboard meanwhile.

## Angular staff portal

The new [Angular portal](admin-web/README.md) provides campus-scoped staff login,
CSV/Excel imports for campuses, students and parent contacts, confirmed parent
account linking, teacher class assignments, attendance entry/CSV upload, and homework
publishing. Apply `backend/portal.sql` once after the initial schema for a new backend.
This migration is already deployed to the connected hosted project.

The portal workflow tests the Angular imports/build and database access isolation.
Its downloadable static build is ready for hosting; no public portal URL is configured.
Flutter's existing attendance and homework screens still use demonstration data;
the next mobile integration must read these new tables. See the portal README for
import templates, staff provisioning, hosting steps and pilot limitations.
