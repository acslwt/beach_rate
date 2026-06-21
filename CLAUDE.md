# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
flutter pub get          # Install / sync dependencies
flutter analyze          # Lint (must return "No issues found" before any commit)
flutter run              # Run on connected device or emulator
flutter run -d linux     # Run on Linux desktop
flutter test             # Run all tests
flutter test test/widget_test.dart  # Run a single test file
flutter build apk        # Android release build
flutter build ios        # iOS release build
```

## Architecture

Single-page Flutter app. No routing, no state management library.

```
lib/
  main.dart              # PlageApp (MaterialApp) → SummerMapPage
  summer_map_page.dart   # The entire UI: map + header + button + marker
```

### `summer_map_page.dart` structure

- `SummerMapPage` (StatefulWidget) owns `MapController`, GPS state (`_userLocation`, `_isLocating`), and button-press animation state.
- `_fetchLocation()` requests GPS via `geolocator`. On success it calls `_finishLocating(loc)`; on any failure/denial it calls `_finishLocating(null)`. No `timeLimit` is set — GPS is allowed to take as long as needed.
- `_finishLocating()` updates state and moves the map with `WidgetsBinding.addPostFrameCallback` (not `Future.delayed`) so the `MapController` is guaranteed to be attached.
- Build is split into three private methods: `_buildMap()`, `_buildHeader()`, `_buildButton()`.
- The `Stack` uses `fit: StackFit.expand` so `FlutterMap` fills the screen as a direct child (no `Positioned.fill` wrapper needed).
- `_PulsingMarker` is a private `StatefulWidget` at the bottom of the file.

### Key dependencies

| Package | Role |
|---|---|
| `flutter_map` | OSM tile rendering (`TileLayer` + `MarkerLayer`) |
| `latlong2` | `LatLng` coordinate type used by flutter_map |
| `geolocator` | Device GPS / location permission |
| `google_fonts` | Nunito font (playful summer style) |

### Platform setup

**Android** (`android/app/src/main/AndroidManifest.xml`): `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, `INTERNET` permissions declared.

**iOS** (`ios/Runner/Info.plist`): `NSLocationWhenInUseUsageDescription` and `NSLocationAlwaysAndWhenInUseUsageDescription` set in French.

### Design tokens (summer palette)

```dart
const Color _sunYellow = Color(0xFFFBBF24);
const Color _sunOrange = Color(0xFFF97316);
const Color _amberText  = Color(0xFF92400E);
```

Font: **Nunito w800** for all visible text. OSM tile URL: `https://tile.openstreetmap.org/{z}/{x}/{y}.png`.

## Lint

`flutter_lints` is active via `analysis_options.yaml`. The linter flags `unnecessary_underscores` — use named params (`context`, `child`) in `AnimatedBuilder.builder` callbacks instead of `_` / `__`.

## Objectif général
Garantir un workflow Git structuré, où chaque tâche est isolée, traçable, et validée manuellement avant intégration.

---

## Principe fondamental : une tâche = une branche persistante

- Une tâche correspond à une seule branche Git.
- Toutes les modifications liées à cette tâche doivent rester sur cette même branche.
- L’agent NE DOIT PAS créer une nouvelle branche pour des ajustements ou évolutions d’une tâche déjà en cours.

### Exemple
Si la tâche est `feature/button-ui` :
- création du bouton
- modifications du style
- corrections de comportement  
  ➡ tout reste dans `feature/button-ui`

---

## Création de branche

Une nouvelle branche n’est créée QUE dans ces cas :
- nouvelle fonctionnalité indépendante
- bug indépendant
- refactor distinct

Types autorisés :
- feature/nom-court
- fix/nom-court
- refactor/nom-court
- chore/nom-court
- test/nom-court

---

## Workflow obligatoire

Pour chaque nouvelle tâche :

1. Créer une branche depuis `develop` (ou `main` si absent)
2. Travailler exclusivement sur cette branche
3. Faire des commits atomiques et cohérents
4. Continuer à utiliser la même branche pour toutes les modifications liées à cette tâche

---

## Interdiction de merge automatique

- AUCUN merge ne doit être effectué sans validation explicite de l’utilisateur.
- L’agent ne doit jamais supposer qu’une tâche est terminée.

---

## Validation de fin de tâche

Le merge vers `develop` (ou `main`) ne peut se faire que si :

- l’utilisateur confirme explicitement que la tâche est terminée
- tous les tests / vérifications nécessaires sont OK
- le code est stable

Ensuite seulement :
1. push de la branche
2. merge vers `develop`
3. suppression de la branche (si demandé ou configuré)

---

## Convention de commit

Respecter Conventional Commits :

- feat: nouvelle fonctionnalité
- fix: correction de bug
- refactor: amélioration structurelle
- chore: maintenance
- test: ajout/modification de tests
- docs: documentation

### Exemples
- feat: add button component
- fix: correct button alignment on mobile
- refactor: simplify button logic

---

## Bonnes pratiques

- Un commit = une seule responsabilité
- Ne pas mélanger plusieurs types de changements
- Garder les branches courtes et liées à une seule intention
- Continuer à travailler sur la même branche tant que la tâche n’est pas validée

---

## Interdictions strictes

- ❌ Pas de commit direct sur `main`
- ❌ Pas de merge sans validation explicite
- ❌ Pas de nouvelle branche pour une tâche déjà en cours
- ❌ Pas de suppositions sur la fin d’une tâche