#!/usr/bin/env bash
set -euo pipefail
: "${DATABASE_URL:?Set DATABASE_URL to an empty disposable PostgreSQL database}"
if [[ "${ALLOW_DISPOSABLE_DATABASE:-}" != 1 ]]; then
  echo 'Set ALLOW_DISPOSABLE_DATABASE=1. Never run this harness against a hosted project.' >&2
  exit 1
fi
cd "$(dirname "$0")"
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f test_bootstrap.sql -f schema.sql -f access_test.sql -f portal.sql -f status_year.sql -f portal_test.sql -f status_year_test.sql -f monthly_fees.sql -f monthly_fees_test.sql -f mobile_features.sql -f mobile_features_test.sql
