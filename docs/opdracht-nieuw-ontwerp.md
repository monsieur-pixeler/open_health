# Opdracht: nieuw ontwerp inbouwen in de iOS-app van Open Health

**Opdrachtgever:** Ramon van Schie
**Datum:** 27 november 2026, bijgewerkt 28 november 2026
**Repo:** `monsieur-pixeler/open_health` (fork van `Th0rgal/open_health`), lokaal in `/Users/ramonvanschie/Developer/open_health`
**Ontwerp-canvas:** https://claude.ai/artifact/RL2DWSJ8bnohRb3h6yUMot

## Doel

Ramon gebruikt zijn Ring 5 zonder Oura-app en zonder abonnement. De iOS-app in deze repo leest de ring rechtstreeks via Bluetooth uit en rekent alles op de iPhone. De app krijgt nu een nieuw ontwerp: de "sfeervolle richting" met vier schermen (Vandaag, Tijdlijn, Slaap, Mijn ring). Die schermen staan al als SwiftUI-code klaar, maar zijn nog nooit gecompileerd en zitten nog niet in de build.

Deze opdracht: het nieuwe ontwerp werkend in de app krijgen, met echte data, naast de bestaande weergave.

## Uitgangssituatie

- De bestaande app bouwt via Xcode Cloud (model-vrije build, zonder Oura-modellen). Build 0.1.2 (3) staat in TestFlight voor groep Intern. Een nieuwe build moet daar handmatig aan groep Intern worden toegevoegd.
- Het Xcode Cloud-tegoed is beperkt (vult aan op 7 december). Push niet voor elke kleine stap naar `main`; bundel wijzigingen.
- Signing staat op team `UL2WF38GWY`, bundle-ID `nl.ramin.openhealth`.
- De koppelsleutel van de ring is uit Ramons iPhone-back-up gehaald en door Ramon zelf bewaard. Een factory reset is niet nodig. Zie `HANDOFF.md`, "Ring en koppelsleutel".
- Het nieuwe ontwerp staat in `apps/ios/OuraApp/Design/`:

| Bestand | Inhoud |
| --- | --- |
| `OHTheme.swift` | Kleuren, afstanden, achtergronden, kaarten, glazen knoppen |
| `OHModels.swift` | View-modellen plus voorbeelddata (`OHSample`) |
| `OHComponents.swift` | Scorering, basislijnbalk, hero, hypnogram, tijdlijnregel |
| `OHTodayView.swift` | Vandaag |
| `OHDayTimelineView.swift` | Tijdlijn |
| `OHSleepView.swift` | Slaap |
| `OHRingView.swift` | Mijn ring |
| `OHAppShell.swift` | `TabView` met de vier tabs |

- Alle types hebben het voorvoegsel `OH`, zodat ze niet botsen met bestaande code.
- De map staat niet in `project.yml` of `project-ci.yml`, dus de huidige build negeert hem.

Lees vóór je begint: `CLAUDE.md`, `HANDOFF.md`, `apps/ios/OuraApp/Design/README.md`, `docs/offline-plan.md` en `docs/clients-web-and-ios.md`.

## Taken

Werk in deze volgorde. Stop na elke taak, laat Ramon zien wat er veranderd is en wacht op akkoord voor de volgende.

### 0. Eerst: de koppeling met de echte ring testen

De sleutel is al opgehaald (28 november) en Ramon bewaart hem zelf. Deze taak test of de app er echt mee werkt.

1. Ramon installeert de huidige build via TestFlight.
2. Ramon plakt de sleutel zelf in het veld "Paste your pairing key" en tikt op **synchroniseren** (`RingSync.run(keyHex:)`). **Niet** op koppelen: `pair` probeert een nieuwe sleutel te installeren.
3. Vraag Ramon nooit om de sleutel in de chat te plakken. Laat hem hem zelf invoeren.
4. Controleer met Ramon dat er metingen binnenkomen in de app én dat de officiële Oura-app nog steeds synchroniseert.

**Klaar als:** beide apps met dezelfde ring synchroniseren. **Lukt het niet**, stop dan en meld wat er misging, met de foutmelding uit de app. Reset de ring niet en installeer geen nieuwe sleutel; dat beslist Ramon.

### 1. In het project opnemen
- Voeg `Design` toe aan `sources` in `project.yml` én in de model-vrije opzet voor Xcode Cloud (`project-ci.yml` en het gecommitte Xcode-project).
- Genereer het project opnieuw.

**Klaar als:** de map in beide projecten staat en de bestaande app ongewijzigd bouwt.

### 2. Compileren
- Bouw voor de iOS-simulator en los alle fouten in `Design/` op.
- Verander niets aan de bestaande schermen.

**Klaar als:** de app zonder fouten en zonder nieuwe waarschuwingen in `Design/` bouwt.

### 3. Previews controleren
- Bekijk alle `#Preview`s in donker en met de grootste tekstgrootte (Dynamic Type).
- Tekst mag niet afgekapt worden, tikvakken zijn minstens 44 pt, elk icoon zonder tekst heeft een toegankelijkheidslabel.
- Als de skills **SwiftUI Pro** of **Axiom** (`axiom-accessibility`) geïnstalleerd zijn: laat ze de vier schermen nalopen en verwerk de bevindingen.

**Klaar als:** screenshots van elk scherm (normaal en grootste tekst) in `docs/screenshots/ontwerp/` staan.

### 4. Echte data koppelen
- Schrijf een mapping van `Summary` (uit `oura-summary`) naar `OHToday`, `OHNight`, `OHTimelineDay` en `OHWeekDay`.
- Schrijf een mapping van de ringstatus in `RingSync` naar `OHRingState`.
- Toon alleen wat de app echt berekent. Ontbreekt een waarde (bijvoorbeeld een score die nog niet bestaat), laat het veld dan leeg of verberg het. Verzin geen getallen.

**Klaar als:** de vier schermen met echte data werken, en er een lijst is van velden die nog ontbreken.

### 5. Acties koppelen
Koppel aan bestaande functies, voeg geen nieuwe functionaliteit toe:
- **Synchroniseren** → bestaande sync in `RingSync`.
- **Sleutel back-uppen** → Keychain (iCloud-sleutelhanger).
- **Ruwe data exporteren** → bestaande export (`RawData` / `ResearchExport`).
- **Ring wissen** → bestaande factory reset. Moet **altijd** eerst om bevestiging vragen.

**Klaar als:** elke knop iets echts doet, of zichtbaar uitgeschakeld is als dat nog niet kan.

### 6. Schakelaar oud/nieuw
- Voeg in de instellingen een schakelaar toe om te kiezen tussen de oude weergave (`RootView`) en het nieuwe ontwerp (`OHAppShell`).
- De oude weergave blijft voorlopig de standaard.

**Klaar als:** Ramon via TestFlight beide weergaven kan proberen.

## Regels

- **Geen materiaal van Oura:** gebruik geen afbeeldingen, iconen, logo's of teksten uit de officiële Oura-app. De ring op "Mijn ring" is getekend en blijft getekend.
- **Nooit committen:** modellen (`.pt`/`.ptl`), `libtorch`, `oura.db`, auth-keys of andere sleutels.
- **Kleine commits** per taak, met een duidelijke boodschap.
- **Ontzie de Mac:** Ramons Mac doet ook ander werk. Draai geen zware builds tegelijk en gebruik de model-vrije build.
- **Twee clients:** volgens `CLAUDE.md` horen nieuwe weergaven ook in het webdashboard. Noteer in `docs/clients-web-and-ios.md` ("Known gaps") wat nog in het webdashboard moet; dat is een aparte opdracht.
- **Geen onomkeerbare acties op de ring:** test "Ring wissen" niet op Ramons echte ring zonder zijn uitdrukkelijke akkoord op dat moment.
- **Bij twijfel:** vraag Ramon, en raad niet.

## Ontwerpregels (samenvatting)

- Donker ontwerp met getekende achtergronden: avondlucht (Vandaag), nachtlucht (Slaap), effen donker (Tijdlijn, Mijn ring).
- Kleuren met betekenis: groenblauw `#7FD1C0` = goed, amber `#E8B86B` = let op, rood `#FF7A6B` alleen voor wissen.
- Koppen in de serif van iOS (New York) via `Font.ohSerif`, de rest in systeemtekststijlen; cijfers met `.monospacedDigit()`.
- Afstanden alleen uit `OHSpace` (4, 8, 12, 16, 24, 32).
- Het canvas is de referentie voor hoe het eruit moet zien; de code is de bron voor hoe het werkt.

## Opleveren

1. Werkende build in Xcode Cloud, beschikbaar in TestFlight.
2. Screenshots in `docs/screenshots/ontwerp/`.
3. Een korte notitie in `HANDOFF.md`: wat er gedaan is, welke velden nog ontbreken, en wat nog open staat voor het webdashboard.

## Buiten deze opdracht

- Eigen slaapfasen en scores berekenen (zie `docs/offline-plan.md`).
- Het webdashboard in de nieuwe stijl bouwen.
- De ring wissen en opnieuw koppelen met een nieuwe sleutel. Dat is niet nodig zolang taak 0 slaagt, en als het ooit wel moet, beslist en doet Ramon dat zelf.
