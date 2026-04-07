# Next.js Frontend Idea

## Goal

Build a separate Next.js frontend and deploy it on Vercel, while deciding carefully how it should connect to Supabase and the existing backend.

## Current Thought

- Use Next.js for a web-first admin/operator UI
- Deploy Next.js on Vercel
- Keep Supabase as the database and auth/data platform
- Keep the Node backend for sensitive admin workflows, protected actions, and any logic we do not want exposed directly from the frontend

## Recommended Architecture

### Option A: Next.js + Supabase + Backend

Best default path.

- Next.js handles the web UI
- Supabase handles auth and database access
- Backend handles protected admin APIs, business rules, app release/version workflows, and anything sensitive

Why this is safer:

- direct browser-to-database access needs careful RLS
- admin features are usually safer through backend APIs
- easier to centralize validation and authorization

### Option B: Next.js + Supabase Direct Only

Possible, but only if:

- Supabase Auth is fully set up
- Row Level Security is correctly configured
- admin permissions are modeled carefully

This can work, but it is riskier if rushed.

## Possible Features For The Next.js Version

- Admin/operator login
- Dashboard for games, credentials, FAQs, discussions, cashouts
- Release management page
- App update history page
- Version upload metadata form
- Download links for app builds

## App Update System Idea

For later discussion:

- Admin uploads release metadata
- Store version, title, notes, file URL, platform, size, changelog
- Flutter app checks latest version from backend
- If newer version exists, show "Update available"
- Show update details and changelog
- Download with progress
- Offer install/open file flow where platform supports it

## Platform Notes

### Flutter Web

- No native installer flow like APK/EXE
- users usually get the latest deployed version automatically

### Android

- Can support APK download/update flow
- installer permissions and package update behavior need handling

### Windows Desktop

- Can support installer or updater flow
- often better with a dedicated updater strategy

### iOS

- cannot do custom self-install like Android
- App Store distribution rules apply

## Questions For Later

- Should Next.js replace Flutter web, or exist alongside it?
- Should Next.js talk directly to Supabase, or mostly through backend APIs?
- Which roles do we need: admin, operator, viewer?
- Do we want release uploads stored in Supabase Storage or somewhere else?
- Which platforms need in-app update support first?

## Suggested Next Step When We Return

Design the release/version data model first, then choose whether the Next.js frontend should be:

- primarily backend-driven
- primarily Supabase-driven
- or hybrid
