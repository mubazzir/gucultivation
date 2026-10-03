# Gu Cultivation

A personal study / cultivation gamification app inspired by the world of *Reverend Insanity*.

Real-world studying becomes cultivation progress. Subjects become Paths. Tasks and events yield Gu worms and materials.

## Features (v1)

- First-time name + random A–E Primeval Essence Aptitude
- Persistent user profile (Hive local database)
- Cultivation timer with timestamp-based session recovery
- Rank 1–9 cultivation + Initial / Middle / Upper / Peak stages
- Exponential progression configuration
- Custom Paths with attainment ranks (Ordinary → Supreme Grandmaster)
- Gu worm collection from Excel data (537 Gu), **hidden until obtained**
- Rank-weighted Gu drops with equal probability within rank
- Materials inventory
- Tasks with difficulty-scaled rewards
- Events
- Refinement
- Status / statistics / streaks
- JSON export/import ready architecture
- **Punishment** page: single button that wipes all progress and shows DEATH

## Requirements

- Flutter 3.16+ (stable)
- Dart 3.2+

## Setup

```bash
cd gu_cultivation
flutter pub get
flutter run
```

## Architecture

```
lib/
  main.dart
  core/
    constants/
    theme/
    database/          # Hive adapters
    providers.dart     # Riverpod
  config/
    cultivation_config.dart
  models/
  services/
    persistence_service.dart
    cultivation_service.dart
    gu_service.dart
  screens/
    onboarding/
    home/
    cultivation/
    status/
    gu/
    paths/
    tasks/
    events/
    inventory/
    refinement/
    punishment/
  widgets/
assets/data/
  gu_worms.json
  materials.json
```

## Persistence

Hive boxes store:

- User profile (name, aptitude, rank, essence, streaks…)
- Cultivation session (start/pause timestamps, accumulated time)
- Paths, owned Gu, materials, tasks, statistics

Closing the app, force-stopping, or rebooting does **not** reset progress.

## Punishment

Bottom navigation → **Punishment** → confirm → entire database wiped → DEATH screen → back to name entry.

## Data source

Gu and Materials were imported from the provided Excel spreadsheet and converted to JSON assets.
