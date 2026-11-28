# Overdracht: eigen Oura-app zonder abonnement

Dit bestand geeft een agent in Claude Code alle context. Lees daarna ook `CLAUDE.md`
en de opdracht in `docs/opdracht-nieuw-ontwerp.md`.

**Laatst bijgewerkt:** 28 november 2026

## Doel
Ramin gebruikt zijn Oura Ring 5 met een eigen iOS-app: geen membership, geen cloud.
Data komt rechtstreeks via Bluetooth van de ring (open_oura) en alles wordt op de
iPhone berekend. Alleen voor eigen gebruik, via TestFlight.

## Stand van zaken

### Repo en build
- Fork: `monsieur-pixeler/open_health` (upstream: `Th0rgal/open_health`), lokaal in
  `/Users/ramonvanschie/Developer/open_health`.
- Signing: team `UL2WF38GWY`, bundle-ID `nl.ramin.openhealth`, in `project.yml` en
  `project-ci.yml`.
- App ID `nl.ramin.openhealth` ("Open Health", HealthKit aan) is geregistreerd.
- App Store Connect: app **Open Health Ramin** (Apple ID 6838963137, SKU
  `openhealth-ios-001`, hoofdtaal Nederlands).
- Xcode Cloud-workflow "Default": push naar `main` → Archive iOS, distributie
  "TestFlight (Internal Testing Only)". Er is geen post-actie: een nieuwe build moet
  in TestFlight handmatig aan groep **Intern** worden toegevoegd.
- Build **0.1.2 (3)** staat in TestFlight op "Testing" voor groep Intern.
- Xcode Cloud bouwt de model-vrije versie: `apps/ios/OuraApp/ci_scripts/ci_post_clone.sh`
  bouwt de Rust-xcframework en genereert het project uit `project-ci.yml`.
- **Let op:** het Xcode Cloud-tegoed was eind november bijna op (vult aan op
  7 december). Elke push naar `main` start een build van ±5 minuten. Bundel
  wijzigingen en push niet voor elke kleine stap.

### Ring en koppelsleutel (opgelost, geen reset nodig)
- De ring bevat één koppelsleutel, en die heeft de officiële Oura-app erin gezet.
- Op 28 november is die sleutel uit een lokale iPhone-back-up gehaald: database
  `assa.sqlite` van de Oura-app, tabel `ringconfiguration`, kolom `auth_key`. De
  ring heet in die database `EFE59E7B2AAA`.
- **Ramin heeft de sleutel zelf veilig bewaard.** Hij staat nergens in deze repo,
  en zo moet het blijven.
- Met deze sleutel werken de Oura-app en deze app naast elkaar. Een factory reset is
  **niet** nodig.
- Hoe de sleutel in de app komt: Ramin plakt hem zelf in het veld
  "Paste your pairing key" en tikt op **synchroniseren** (`RingSync.run(keyHex:)`).
  Niet op koppelen: `pair` probeert een nieuwe sleutel te installeren en werkt alleen
  op een gewiste ring.

### Ontwerp
- Gekozen: de "sfeervolle richting". Canvas met de vier iOS-schermen en het
  webdashboard: https://claude.ai/artifact/RL2DWSJ8bnohRb3h6yUMot
- De vier schermen staan als SwiftUI in `apps/ios/OuraApp/Design/` (Vandaag,
  Tijdlijn, Slaap, Mijn ring en `OHAppShell` met de tabs). **Nog nooit gecompileerd en
  nog niet in de build.** Zie `apps/ios/OuraApp/Design/README.md`.

### Offline rekenen
- Plan: `docs/offline-plan.md`. Wat al zonder model werkt (HRV, basislijn, temperatuur,
  SpO₂, activiteit, slaapschuld) en hoe slaapfasen en scores zonder Oura's modellen
  komen.

## Nog te doen (in deze volgorde)

De actuele stand (welke stap loopt, wat op Ramin wacht) staat in het Regiepaneel en in
`~/.claude/regie/post/plan/open-health.json` (mijlpalen M1–M4); deze lijst is de volgorde waar dat plan uit komt.

1. **App testen met de echte ring.** Ramin installeert build 0.1.2 (3) via TestFlight,
   plakt de sleutel en synchroniseert. Controleer daarna dat de officiële Oura-app ook
   nog synchroniseert. Dit is de eerste echte test van de koppeling.
2. **Nieuw ontwerp inbouwen.** Volledige opdracht met taken, "klaar als" en regels:
   `docs/opdracht-nieuw-ontwerp.md`.
3. **Eigen slaapfasen en scores** volgens `docs/offline-plan.md`.
4. **Webdashboard** in de nieuwe stijl (staat op het canvas).

## Regels voor elke agent
- **Sleutel:** vraag Ramin nooit om de sleutel in de chat te plakken. Toon, log of
  commit hem nooit. Hij hoort alleen in de Keychain van de app.
- **Ring:** reset de ring nooit en installeer nooit een nieuwe sleutel zonder Ramins
  uitdrukkelijke akkoord op dat moment.
- **Nooit committen:** modellen (`.pt`/`.ptl`), `libtorch`, `oura.db`, back-ups of
  sleutels (staan in `.gitignore`).
- **Geen materiaal van Oura:** geen afbeeldingen, iconen, logo's of teksten uit de
  officiële Oura-app. Oura's PyTorch-modellen zijn hun eigendom; die horen niet in de
  repo.
- **Twee clients:** volgens `CLAUDE.md` horen wijzigingen in zowel de iOS-app als het
  webdashboard. Doe je bewust maar één, noteer dat in `docs/clients-web-and-ios.md`.
- **Ontzie de Mac:** Ramins Mac doet ook ander werk. Geen zware builds tegelijk.
- **Bij twijfel:** vraag Ramin, en raad niet.

## Kleine punten
- `build_run.sh` en `build_run_torch.sh` gebruiken nog bundle-ID `md.thomas.openoura`
  (alleen voor de simulator); aanpassen als die scripts gebruikt worden.
