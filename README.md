# paramedic-triage-offline-app
Offline-first Paramedic Triage Intake mobile application built with Flutter, featuring local persistence, automatic background synchronization.

Stack:  **Flutter (Dart)**, **BLoC**, **Hive**, and **connectivity_plus**.

## Architecture
The app is layered so that the UI is entirely decoupled from persistence and sync logic. Each layer only knows about the one directly beneath it:

# Architecture

```text
┌─────────────────────────────────────────────┐
│ UI (Triage Form Screen)                     │
│ - Displays data                             │
│ - Sends user actions to the BLoC            │
└───────────────────┬─────────────────────────┘
                    │ Events / States
                    ▼
┌─────────────────────────────────────────────┐
│ TriageBloc (flutter_bloc)                   │
│ - Handles business logic                    │
│ - Emits UI states                           │
│ - Calls the repository                      │
└───────────────────┬─────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────┐
│ TriageRepo                           │
│ - Offline-first logic                       │
│ - Saves locally                             │
│ - Uploads pending records                   │
└───────────────┬───────────────────┬─────────┘
                │                   │
                ▼                   ▼
┌──────────────────────┐   ┌──────────────────────┐
│ LocalStore (Hive)    │   │ MockApiClient        │
│ - Stores data offline│   │ - Simulates API      │
│ - Reads pending data │   │ - 2s delay           │
└──────────────────────┘   └──────────────────────┘

              ▲
              │
┌─────────────────────────────────────────────┐
│ SyncService                                 │
│ - Listens for connectivity changes          │
│ - Syncs pending records automatically       │
│ - Runs when app resumes                     │
└─────────────────────────────────────────────┘
```

## Project Layout

```text
lib/
├── main.dart                          # App entry point, wires repo/bloc/sync together
├── core/
│   ├── domain/
│   │   └── triage_record.dart         # TriageRecord model, TriageStatus, SyncStatus
│   ├── data/
│   │   ├── local_store.dart           # Hive-backed local persistence (LocalStore)
│   │   ├── mock_api_client.dart       # Simulated backend (MockAPIClient)
│   │   └── triage_repo.dart           # Offline-first repository (TriageRepo)
│   └── sync/
│       └── sync_service.dart          # Connectivity watcher, triggers background sync
└── screens/
    └── triage_form_screen/
        ├── triage_form_screen.dart    # Triage intake screen (form + logged patients)
        ├── bloc/
        │   ├── triage_bloc.dart       # TriageBloc
        │   ├── triage_event.dart      # Bloc events
        │   └── triage_state.dart      # Bloc state
        └── widgets/
            ├── priority_selector.dart # P1-P5 priority picker
            └── record_card.dart       # Logged patient card with sync status

test/
├── triage_repo_test.dart              # TriageRepo offline/sync behaviour
└── triage_bloc_test.dart              # TriageBloc behaviour
```

## How the sync queue works
**The core invariant: local write first, always.**

1. **Submit** — when the paramedic taps *Save triage record*, the repository builds a `TriageRecord` with a device-generated UUID and `syncStatus: queued`, and **awaits the Hive write before doing anything else**. The moment that await completes, the data can no longer be lost — airplane mode, app killed, battery pulled, all safe. The UI is confirmed immediately.
2. **Best-effort upload** — an upload is then attempted fire-and-forget (never blocking the UI). Success → `synced`. Any failure → `failed`, which simply means "still in the queue".
3. **Queue drain** — `syncPending()` fetches every `queued`/`failed` record **oldest-first** (so the server receives records in capture order) and uploads them sequentially, updating each record's badge live via Hive's watch stream.
4. **Drain triggers** — the `SyncService` calls `syncPending()` when:
   - connectivity transitions from offline → online (`connectivity_plus` stream),
   - the app returns to the foreground (`WidgetsBindingObserver` — covers connectivity events missed while the OS had the app suspended),
   - app cold-start (drains anything left over from a previous session),
   - the user taps the optional *Sync now* button.
5. **Concurrency guard** — Android fires connectivity events in rapid bursts, and resume + reconnect often arrive together. A simple `_draining` latch collapses overlapping drain requests into one, preventing double-uploads (covered by a dedicated unit test).
6. **Crash safety** — a record persisted mid-upload as `syncing` is deliberately written to disk as `queued`, so a crash during upload can never strand a record in a stuck state.

### Device lifecycle handling

| Event | Behaviour |
|---|---|
| App minimised mid-upload | In-flight attempt may complete or fail; either way the record's disk state is consistent (`synced` or `queued`) |
| App resumed | `didChangeAppLifecycleState(resumed)` triggers a drain — anything missed while suspended is retried |
| App killed / restarted | Cold-start drain in `SyncService.start()` picks up all leftovers |


## The UI
Single screen, optimised for fast thumb input under pressure:

- **Priority selector** — five 64px-tall tap targets in one row (no dropdown, no scrolling). P1 (deep red `#B71C1C`) and P2 (deep orange `#E65100`) are visually dominant with a warning glyph, so criticality is not encoded by colour alone; P3–P5 are deliberately muted.
- **Critical record cards** — P1/P2 entries get a thick hazard rail and tinted background, scannable at arm's length.
- **Sync badges** — every record shows *Pending sync* (amber) / *Syncing…* / *Synced* (green) / *Retry pending*, making the offline queue visibly trustworthy.
- **Offline banner** — an amber strip appears when connectivity drops: *"Offline — records save on device and sync later"*. Submitting offline is a first-class flow, not an error.
- **Validation** — name and condition cannot be blank; a priority must be selected. Inline errors, no dialogs.
- **Debug failure switch** (bug icon, app bar) — forces the mock API to return failures so the retry queue can be demonstrated on demand.

## Setup

Prerequisites: Flutter SDK ≥ 3.19 (Dart ≥ 3.3), an Android/iOS device or emulator.

```bash
git clone <this-repo>
cd paramedic_triage

flutter create . --platforms=android,ios

flutter pub get
flutter run
```

### Run the tests

```bash
flutter test
```

Covers: offline durability (record survives failed upload), successful sync, oldest-first full-queue drain, partial-failure retry, the concurrent-drain latch, input trimming, and BLoC event handling.

## Demo script (airplane-mode walkthrough)
1. Launch the app online — submit a record → badge goes *Syncing…* → *Synced* (green) after the simulated 2s latency.
2. Enable **Airplane Mode** — amber offline banner appears.
3. Submit two more records → snackbar confirms *"Record saved on device — will sync when back online"*; both cards show amber *Pending sync* badges. No error screens, UI never blocks.
4. Disable Airplane Mode — within moments the sync service detects restoration and drains the queue automatically: badges flip *Syncing…* → *Synced* one by one, oldest first, with zero user intervention.
5. (Optional) Toggle the bug switch to force failures, submit, watch records park as *Retry pending*, then toggle off and tap *Sync now* to watch them recover.