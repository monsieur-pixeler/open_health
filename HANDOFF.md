# Overdracht: eigen Oura-app zonder abonnement

Dit bestand geeft Claude Code de context van een eerder gesprek. Lees ook `CLAUDE.md`.

## Doel
Een eigen versie van deze app voor de Oura Ring 5, op de iPhone van de eigenaar, zonder
Oura-app en zonder membership. Data komt rechtstreeks via Bluetooth van de ring
(open_oura). Eerst voor eigen gebruik via TestFlight, later eventueel een eigen ontwerp
en eigen scores.

## Stand van zaken
- Fork: `monsieur-pixeler/open_health` (upstream: `Th0rgal/open_health`).
- Gedaan: in `apps/ios/OuraApp/project.yml` en `project-ci.yml` staat
  `DEVELOPMENT_TEAM: "UL2WF38GWY"` en bundle-ID `nl.ramin.openhealth`.
- Build-route: **Xcode Cloud**. De Mac van de eigenaar is vaak druk met ander werk, dus
  zware lokale builds vermijden. Xcode Cloud draait `apps/ios/OuraApp/ci_scripts/ci_post_clone.sh`, dat
  de Rust-xcframework bouwt en het project genereert uit `project-ci.yml` (versie
  zonder on-device AI-modellen).

- Gedaan (2026-11-25): stap 1 en 2 hieronder. App ID `nl.ramin.openhealth` ("Open Health",
  HealthKit aan) is geregistreerd; app **Open Health Ramin** staat in App Store Connect
  (Apple ID 6838963137, SKU `openhealth-ios-001`, hoofdtaal Nederlands).
- Gedaan (2026-11-25): stap 3. Xcode Cloud-workflow "Default": push naar `main` → Archive iOS
  met Distribution Preparation "TestFlight (Internal Testing Only)". Geen post-actie; een
  Xcode Cloud-build moet je in TestFlight handmatig aan groep **Intern** toevoegen
  (of voeg de post-actie "TestFlight Internal Testing" met groep Intern toe).
  Build 0.1.2 (3) staat in TestFlight op "Testing" voor groep Intern. Verder bij stap 4:
  installeren via de TestFlight-app en de ring koppelen.
- Let op: Xcode Cloud-tegoed was eind november bijna op (vult aan op 7 december); elke
  push naar `main` start een build van ±5 minuten.

## Nog te doen (in deze volgorde)
1. **App ID registreren** op developer.apple.com → Identifiers: `nl.ramin.openhealth`,
   met capability **HealthKit** aan. Inloggen doet de eigenaar zelf.
2. **App aanmaken** in App Store Connect met die bundle-ID.
3. **Xcode Cloud-workflow** (eenmalig in Xcode):
   ```
   cd apps/ios/OuraApp && xcodegen generate --spec project-ci.yml && open OuraApp.xcodeproj
   ```
   Daarna Product → Xcode Cloud → Create Workflow: start bij push naar `main`,
   Action = Archive, Post-action = TestFlight (Internal). GitHub-toegang tot de fork
   geven.
4. Eerste build controleren en installeren via TestFlight. Ring koppelen in de app.
5. Daarna: eigen ontwerp en eigen scores (zie hieronder).

## Belangrijke aandachtspunten
- De officiële scores (Readiness, Sleep, Activity, Stress) komen van Oura's eigen
  PyTorch-modellen. Die zijn hun IP en staan niet in de repo; niet toevoegen of
  committen. Eigen scores bouwen op ruwe data (HR, HRV, temperatuur, beweging,
  on-device slaapfasen) is de bedoeling.
- Nooit modellen, `libtorch`, `oura.db` of auth-keys committen (staan in `.gitignore`).
- Niet de naam/het logo "Oura" gebruiken als de app ooit publiek gaat; dan ook
  juridisch laten checken (gebruiksvoorwaarden, App Store-review).
- Wijzigingen aan data/UI horen volgens `CLAUDE.md` in zowel de iOS-app als het
  webdashboard.
- `build_run.sh` en `build_run_torch.sh` bevatten nog `md.thomas.openoura` als
  bundle-ID (alleen voor de simulator); aanpassen als die scripts gebruikt worden.

## Nieuw ontwerp (27 november)
De gekozen "sfeervolle richting" staat als SwiftUI in `apps/ios/OuraApp/Design/`
(Vandaag, Tijdlijn, Slaap, Mijn ring en een `TabView`). Nog niet gecompileerd en nog niet in
de build. Stappen om het in te bouwen: `apps/ios/OuraApp/Design/README.md`.
Ontwerp-canvas: https://claude.ai/artifact/RL2DWSJ8bnohRb3h6yUMot
