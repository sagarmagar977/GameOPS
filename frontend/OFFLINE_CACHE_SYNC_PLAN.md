# Offline, Cache, Sync, and UX Improvement Plan

This file captures the requested app behavior and the recommended implementation order for the Flutter frontend.

## Main goals

- Load the app from cache first, even after the app is fully closed and reopened.
- If the user is already logged in, do not block the app on internet every time.
- Keep cached data visible until background sync finishes.
- Sync with the backend when internet becomes available again.
- Support offline use as much as possible for current screens.
- Show remembered login details on the login screen after logout.
- Improve speed and perceived speed with skeleton loading and smoother navigation.
- Add swipe/slide navigation between app sections instead of only tapping the nav bar.

## Expected behavior

### Startup behavior

- App opens immediately into the cached shell UI.
- If there is a saved session, restore it locally first.
- Do not wait for `/auth/me` before showing the app UI.
- Verify token and refresh account data in the background.
- If verification fails, keep the user informed and route safely to login.

### Cached screen behavior

- Each screen loads cached data first.
- Cached data remains visible while a background refresh runs.
- When fresh data arrives, update the screen without showing a full-page loading blocker.
- If offline, continue using cached data.

### App close and reopen behavior

- Cached dashboard, games, rules, and cashouts remain available after app restart.
- Reopening the app should show cached content immediately.
- Network refresh should happen after the cached version is already visible.

### Offline action behavior

- New cashouts created offline should be stored in a pending sync queue.
- Pending actions should sync automatically when internet returns.
- Synced items should be marked complete and removed from the pending queue.
- Failed sync attempts should be retried safely.

### Logout and remembered login behavior

- Logging out should not erase the remembered login identifier by default.
- Login screen should show the previous email or username for convenience.
- Auth token and protected session data must still be cleared on logout.

### Navigation behavior

- Main sections should support horizontal swipe navigation.
- Top navigation bar should stay in sync with swipe position.
- Screen state should stay alive when moving between tabs where practical.

## Requested features list

### 1. Cache-first app startup

Implement:

- Restore saved user session from local storage first.
- Open `HomeShell` immediately if a valid local session exists.
- Run `/auth/me` in the background instead of blocking startup.
- Keep a lightweight startup skeleton only for first-ever launch when no cache exists.

Why:

- This removes the "wait on internet before app shows" feeling.

## 2. Persistent cached data for current screens

Implement local persistence for:

- dashboard payload
- games list
- cashout rules
- cashouts list
- user/session summary

Recommended storage:

- Use `Hive` for cached screen payloads and pending sync queue.
- Keep `SharedPreferences` for simple session flags and remembered login text if desired.

Behavior:

- Load cached payload instantly.
- Refresh only after cached data is displayed.
- Keep old cached data visible until fresh sync completes.

## 3. Background sync strategy

Implement:

- Repository layer per screen or feature.
- `loadCached()` then `refreshRemote()` flow.
- Connectivity-aware retry for failed refreshes.
- Sync only the current screen first to keep scope safe.

Suggested order:

- Dashboard sync first
- Games sync second
- Cashouts sync third
- Other screens later

## 4. Offline queue for write actions

Implement:

- Queue cashout creation requests when offline.
- Store pending payloads locally with metadata such as:
  - local id
  - created timestamp
  - sync status
  - retry count
- Attempt sync when app resumes or internet returns.
- Update UI optimistically so the user sees the offline-created record immediately.

## 5. Remembered login identifier after logout

Implement:

- Save the last successful login email or username separately from the auth session.
- On logout:
  - clear token
  - clear protected session
  - keep remembered login identifier
- Prefill the login field next time the login screen is shown.



## 6. Skeleton loading instead of blank waiting

Implement:

- App startup skeleton
- Dashboard skeleton matching row/stat layout
- Games list skeleton rows
- Small inline refresh indicators instead of full-screen blockers

Goal:

- Improve perceived speed even when data is still refreshing.

## 7. Swipe navigation between sections

Implement in `HomeShell`:

- Replace manual single-screen tab rendering with `PageView`
- Add `PageController`
- Sync selected nav item with page swipes
- Preserve existing top nav buttons

Benefits:

- User can move between sections by sliding horizontally.
- App feels more fluid and native.

## 8. Performance improvements

Implement:

- Avoid rebuilding whole pages unnecessarily
- Keep tab pages alive when switching
- Reuse cached in-memory data during current app session
- Avoid full reload after every small action
- Refresh only affected sections when possible
- Prefer row placeholders and incremental refresh over full spinners

Potential extras later:

- Debounce refresh triggers
- Paginate long cashout lists
- Lazy-build larger lists

## 9. Security and data handling rules

Must keep in mind:

- Cached auth token should be handled separately from cached screen data.
- Logout must clear protected session/token data.
- Remembered login email is okay to keep if the product wants convenience.
- Sensitive data should not remain in cache after explicit logout unless intentionally allowed.

## Implementation order

### Phase 1

- Add plan file
- Add remembered login identifier storage
- Make app startup cache-first instead of network-blocking

### Phase 2

- Add local cache layer for dashboard
- Show dashboard cached data first
- Add dashboard skeleton loading and background refresh

### Phase 3

- Add `PageView` swipe navigation in `HomeShell`
- Keep tab state alive between section changes

### Phase 4

- Add local cache layer for games screen
- Add games skeleton loading

### Phase 5

- Add offline write queue for cashouts
- Add reconnect sync flow
- Mark pending and synced items in UI if needed

### Phase 6

- Extend the same repository/cache pattern to remaining screens
- Add more granular refresh behavior
- Polish loading states and error handling

## Suggested code structure

Possible frontend additions:

- `lib/core/connectivity_service.dart`
- `lib/core/remembered_login_storage.dart`
- `lib/repositories/dashboard_repository.dart`
- `lib/repositories/games_repository.dart`
- `lib/services/pending_sync_service.dart`
- `lib/models/pending_cashout.dart`
- `lib/widgets/skeleton_box.dart`
- `lib/widgets/dashboard_skeleton.dart`
- `lib/widgets/list_row_skeleton.dart`

## Notes for implementation

- Start with the dashboard only for cache-first sync to reduce risk.
- Do not switch the entire app to offline queueing in one step.
- Show cached content immediately, even if it may be slightly stale.
- Refresh in the background and patch the UI quietly.
- Prefer incremental rollout over a large one-shot refactor.

## Acceptance checklist

- [ ] App can reopen and show cached content before network responds
- [ ] Logged-in user is not blocked by internet at every launch
- [ ] Dashboard loads cached version first
- [ ] Dashboard refreshes in background
- [ ] Games screen can load cached version first
- [ ] Offline cashout creation is queued locally
- [ ] Pending cashouts sync when internet returns
- [ ] Login screen shows previous login identifier after logout
- [ ] Skeleton loading replaces blank waiting states
- [ ] User can swipe between main sections
- [ ] Tab state is preserved across navigation
- [ ] App feels faster on reopen and during refresh
