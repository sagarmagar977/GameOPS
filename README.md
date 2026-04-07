# GameOps Starter

This repository contains a first-pass starter for the product described in `prd.md`.

- `backend/`: Node.js + Express API prepared for Supabase
- `frontend/`: Flutter app starter for game management, credentials, cashouts, and FAQ/discussions
- `supabase/`: SQL schema for the initial database

## What is included

- Manage available games with active/highlighted states
- Store multiple credentials per game
- Mark one credential as the primary login
- Track cashout rules and recent cashouts
- Search FAQs and discussions
- Trigger placeholder automation tasks from the backend

## Backend setup

1. Copy `backend/.env.example` to `backend/.env.local` or `backend/.env`
2. Fill in your Supabase project URL, service role key, and database connection string
3. Install dependencies:

```powershell
cd backend
npm.cmd install
```

4. Run the database migration:

```powershell
npm.cmd run migrate
```

5. Start the server:

```powershell
npm.cmd run dev
```

The API runs on `http://localhost:4000` by default.

## Flutter setup

Flutter is not installed in the current workspace environment, so the app was scaffolded manually.

```powershell
cd frontend
flutter pub get
flutter run
```

If your backend runs elsewhere, update `apiBaseUrl` in `frontend/lib/core/config.dart`.
