# DHACSS Angular staff portal

Angular 22 with Supabase Auth/PostgreSQL. This is a separate admin/teacher frontend;
the Flutter app remains the parent-facing mobile client. Use the same account credentials.

## Included

- Staff-only entry, live campus counts, paginated database reads and student search.
- Excel `.xlsx` and CSV imports for campuses, students, parent contact records.
- Downloadable blank Excel/CSV templates, local validation, 20-row preview and explicit approval.
- Server-authorized **atomic** imports: if any row fails, no rows from that upload are saved.
- Confirmed parent accounts link by email. Unregistered/unconfirmed emails remain pending.
- Campus administrators can assign an existing confirmed teacher account to a class.
- Teachers see only assigned class rosters and can mark/correct attendance or upload CSV.
- Text homework publishing, with subject, instructions and due date.

## Local development

Use Node 24.19 or a compatible Angular 22 runtime.

```sh
cd admin-web
npm ci
npm test
npm start
```

`npm run build` produces `dist/portal/browser`. The client configuration in
`src/app/data.ts` contains the existing project's **publishable key only**.
Never place a Supabase service-role/secret key in this application.

## Import order and column definitions

1. **Campuses** (head office only): `campus_code`, `campus_name`.
2. **Students**: `campus_code`, `admission_number`, `student_name`, `class_name`.
3. **Parents**: `campus_code`, `admission_number`, `parent_name`, `parent_email`, `phone`.

Campus codes, admission numbers and class names match exactly, including case.
For example, use `CREEK`, `000123` and `Grade 5-A` consistently. Format identifier and
phone columns as **Text** in Excel. Parent email is trimmed and lowercased. Only phone
is optional. Upload at most 500 rows and 5 MB, with exactly one worksheet for XLSX.
Do not include formulas or extra columns. Existing records are never overwritten.
To link two children to one parent, add one row per child with the same parent email.

Review the entire source file before checking the approval box. The screen shows only
the first 20 preview rows; validation checks every row. A failed server import includes
the data-row index (1 is the first row after the header). Fix the file and retry.

**Parents imported here are contact records, not new Auth accounts.** After creating
and confirming their account in Supabase, select **Link confirmed account** in the
Parent records screen. The server checks campus permissions and the email match.
Existing parent links created in the mobile prototype remain intact; they are not
automatically converted into contact records.

## Teacher workflow

Create and confirm the teacher's login in Supabase. A campus administrator uses the
teacher's email to assign a campus and an existing class. One account can have several
assignments. Removing an assignment currently requires the Supabase dashboard.

Select campus, class and date in Attendance. Load the existing register before making
corrections, or upload a CSV with `admission_number,status`. Status must be `present`,
`absent`, `late` or `excused`. Uploading only fills the review form; **Save attendance**
commits the register. Choose a status for every student. Saving the same student/date
updates the existing entry atomically. Future dates are rejected.

Publish homework for a selected class. Attachments, homework submission/grading,
notification delivery and invitation emails are later milestones. The current Flutter
connected dashboard does not yet display the new attendance/homework tables; its demo
screens remain illustrative. The backend already grants linked parents scoped reads.

## Backend and tests

`backend/portal.sql` is the additive schema applied after `backend/schema.sql`.
The hosted project already has this schema. Do not apply the initial schema twice.
`backend/portal_test.sql` tests imports and role boundaries inside a rolled-back
transaction; fixtures are synthetic and do not create working login accounts.
The disposable CI harness runs all backend scripts in order with `bash backend/test.sh`.

## Hosting

The `angular-portal` GitHub Actions artifact is a deployable static web build.
For Cloudflare Pages, select this repository, set root directory `admin-web`, build
command `npm ci && npm run build`, output `dist/portal/browser`, and Node `24.19.0`.
A `pages.dev` address is sufficient; no purchased domain is needed. Alternatively,
upload the contents of the build folder through Cloudflare Pages Direct Upload.
No Cloudflare account has been connected or deployment created yet.

The portal uses one application URL with internal navigation, so no server-side
Angular rendering is needed. Production rollout still needs invitation/recovery
configuration, backups, device/UAT testing and appropriate hosting capacity.
