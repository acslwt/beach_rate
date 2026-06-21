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
  summer_map_page.dart   # Entire UI: map + search + weather pill + button + marker
```

### `summer_map_page.dart` structure

Top-level symbols (in order):

| Symbol | Type | Role |
|---|---|---|
| `_sunYellow/Orange/amberText/grey*/ink` | `const Color` | Design tokens — all colors defined here, never inline |
| `_greyscale` | `const ColorFilter` | Luminance matrix applied to suggestion emojis |
| `_defaultCenter` | `const LatLng` | Paris fallback when GPS unavailable |
| `_Place` | `class` | Nominatim result: `name`, `lat`, `lon` |
| `SummerMapPage` | `StatefulWidget` | Root page widget |
| `_GlassContainer` | `StatelessWidget` | Shared glassmorphism card (backdrop blur + white border + shadow) |
| `_PulsingMarker` | `StatefulWidget` | Animated orange dot on user position |

**`_SummerMapPageState` state buckets:**
- **Map**: `_mapController`, `_center`, `_userLocation`, `_isLocating`, `_buttonPressed`
- **Search**: `_searchCtrl`, `_searchFocus`, `_searchFocused`, `_places`, `_searching`, `_debounce`

**Build methods chain:**
```
build()
 ├── _buildMap()            # FlutterMap + TileLayer + MarkerLayer
 ├── _buildTopOverlay()     # Positioned(top) containing:
 │    ├── _buildSearchBar() # glassmorphism input (top)
 │    ├── _buildDropdown()  # AnimatedSize wrapper → suggestions OR results
 │    │    ├── _buildSuggestions()  # 4 grey chips with greyscale emoji
 │    │    └── _buildResults()      # Nominatim list / spinner / empty state
 │    └── _buildWeatherPill()       # "😊 Temps ensoleillé" (below search)
 └── _buildButton()         # Positioned(bottom) "Je suis ici" pill
```

**Search flow:**
1. `_onSearchChanged()` → debounce 450 ms → `_doSearch()` (Nominatim HTTPS, no API key)
2. Suggestion chip tap → `_tapSuggestion()` → immediate `_doSearch()` (no debounce)
3. Result tap → `_selectPlace()` → `_mapController.move()` + unfocus + clear
4. Map tap / pan → `_searchFocus.unfocus()` via `MapOptions.onTap` + `onPositionChanged`

**`_GlassContainer`**: accepts `radius`, `padding`, `bg`, `shadowColor` — use it for every overlay surface to keep glass style consistent.

### Key dependencies

| Package | Role |
|---|---|
| `flutter_map` | OSM tile rendering (`TileLayer` + `MarkerLayer`) |
| `latlong2` | `LatLng` coordinate type used by flutter_map |
| `geolocator` | Device GPS / location permission |
| `google_fonts` | Nunito font (playful summer style) |
| `http` | Nominatim geocoding requests (declared explicitly, also a transitive dep of flutter_map) |

### Platform setup

**Android** (`android/app/src/main/AndroidManifest.xml`): `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, `INTERNET` permissions declared.

**iOS** (`ios/Runner/Info.plist`): `NSLocationWhenInUseUsageDescription` and `NSLocationAlwaysAndWhenInUseUsageDescription` set in French.

### Design tokens (summer palette)

```dart
const Color _sunYellow = Color(0xFFFBBF24); // button gradient start
const Color _sunOrange = Color(0xFFF97316); // button gradient end, markers, spinner
const Color _amberText = Color(0xFF92400E); // weather pill text
const Color _grey500   = Color(0xFF6B7280); // search icons, hint, chip labels
const Color _grey200   = Color(0xFFE5E7EB); // chip backgrounds, dividers
const Color _ink       = Color(0xFF374151); // search input text, result names
```

Font: **Nunito w800** for all visible text (w600 for search input, w700 for chip labels, w500 for hints). OSM tile URL: `https://tile.openstreetmap.org/{z}/{x}/{y}.png`. Nominatim geocoding: `https://nominatim.openstreetmap.org/search` — `accept-language: fr`, `limit: 5`, `User-Agent` header required.

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