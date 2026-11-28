# Plan M1 — Nieuw ontwerp op iOS (stappen b–g)

Klus `m1-nieuw-ontwerp/plan`, mijlpaal M1/b–g (`~/.claude/regie/post/plan/open-health.json`). Bron: `docs/opdracht-nieuw-ontwerp.md` taken 1–6.
Taak 0 (ringtest) en stap h (eindkeuring, één push, TestFlight) zijn van Ramin en staan hier niet als bouwstap.
Opgesteld 28 nov 2026 door goal-planner, ronde 2 na planreview. **Status: wacht op antwoorden op de vragenpagina (onderaan).**

## Klaar als

1. **Design zit in beide builds.**
   - `- path: Design` (met `excludes: [README.md]`) staat in `project.yml` en `project-ci.yml`.
   - Het gecommitte `OuraApp.xcodeproj`, gegenereerd uit `project-ci.yml`, bevat de OH-bestanden.
   - De model-vrije simulatorbuild slaagt met **0 fouten en 0 waarschuwingen in `Design/`**.
   - Bewijs: buildlog via `testslot.sh` (`grep -c "Design/.*warning:"` = 0) en `git diff --stat` op de pbxproj (alleen toevoegingen; `xcshareddata/xcodecloud/manifest.json` ongewijzigd).
2. **Previews gekeurd.**
   - In `docs/screenshots/ontwerp/` staan: de 4 schermen × standaard en `accessibility5` met voorbeelddata (stap d), en daarna dezelfde 4 schermen met mapping-uitvoer uit de vaste invoer, inclusief de lege toestand op `accessibility5` (na stap f). Alles donker.
   - Elke regel uit de vier `REFERENTIE.md`'s is groen bij `goal-designer` + `axiom:accessibility-auditor`.
3. **Echte data, niets verzonnen.** XCTest `OHSummaryMappingTests` slaagt op vier synthetische invoer-JSON's:
   - `staged`: nacht met ringslaapfasen;
   - `offset`: `stages_t0_unix` = `start_unix` + 600;
   - `partial`: deels gestaged, met codes buiten 1…4;
   - `empty`: lege summary.

   Elke getoonde waarde is terug te voeren op een `Summary`-veld. Ontbrekend = `nil` = leeg vak.

   Fasesegmenten liggen binnen [0,1] en overlappen niet; een gat (zoals de eerste 600 s of codes buiten 1…4) blijft leeg en wordt niet opgevuld.

   `OHScore.average` en `OHScore.tone` zijn `nil` zolang er geen bronveld is (expliciete assert).

   Plus een lijst ontbrekende velden in `HANDOFF.md`.
4. **Elke knop doet iets echts of is zichtbaar uit.**
   - Synchroniseren → `RingSync.run`. Uit alleen bij `ring.busy` of geen sleutel.
   - Ruwe data → `exportRawDatabase` + deelvenster.
   - Ring wissen → `factoryReset`, alleen na een bevestiging die het serienummer noemt. Uit bij geen sleutel, `ring.busy` of geen `knownSerial`.
   - Sleutel back-uppen volgens vraag 3.

   Bewijs: XCTest `OHRingActionsTests` + auditor-keuring. **Nooit** uitgevoerd op de echte ring.
5. **Schakelaar oud/nieuw.** Standaard de oude weergave. Aan/uit in Profiel (oude weergave), terug via "Oude weergave" op Mijn ring.
   - Bewijs: XCTest `DesignSwitchTests` (standaardwaarde `false`; met `ui.newDesign` = true kiest `RootView` de nieuwe tak).
   - Simulatorstart met launch-argument `-ui.newDesign NO` en `-ui.newDesign YES`; beide starten zonder fout. De sleutel is `@AppStorage`, dus `UserDefaults`-argumentdomein.
   - Daarna Ramins iPhone in stap h.
6. **Webdashboard genoteerd.** Regels in `docs/clients-web-and-ios.md` "Known gaps (iOS-only)" voor de vier schermen, de schakelaar en de tweeling-kopie van de stadiumvoorkeur. Plus een korte notitie in `HANDOFF.md`.

## Eindpunt

Ramin zet in Profiel "Nieuw ontwerp (proef)" aan en ziet onderin vier tabs (Vandaag, Tijdlijn, Slaap, Ring) met zijn eigen ringdata. Vakken die de app nog niet berekent blijven leeg, de knoppen op Mijn ring werken, en met één tik gaat hij terug naar de oude weergave.

## Voorkennis (platform, opslag, privacy, release)

- **`apps/ios/OuraCore.xcframework` bestaat niet op deze Mac** (gemeten, `ls`: no such file). `apps/ios/build-xcframework.sh` bouwt hem: installeert ontbrekende iOS-targets (`:14-16`), bouwt `oura-core` en herschrijft de gecommitte `apps/ios/generated/oura_core.swift` en `oura_coreFFI.h` (`:18-23`).
- Model-vrije iOS gebruikt `NoModelRunner` (`crates/oura-core/src/lib.rs:37-40`), die niets teruggeeft (`crates/oura-summary/src/lib.rs:102-107`).
- Slaapfasen komen dan alleen uit de ring zelf (`sleep_phase_data`, `oura-summary/src/lib.rs:2441-2445`). Signaal-staging (`lib.rs:1288`) draait alleen in de web-`PythonRunner` (`crates/oura-cli/src/dashboard.rs:224`) en in Swift onder `#if TORCH` (`SleepStaging.swift:144,274`).
- De slaapscore alleen bij complete staging (`lib.rs:2670`). Of de Ring 5 zelf slaapfasen stuurt: **niet kunnen nagaan** (M2/a).
- Herstel- en activiteitsscore bestaan nergens in Rust of Swift; "Readiness" in de CLI loopt via Python (`crates/oura-cli/src/main.rs:750`).
- Sleutel: `Keychain.saveKey` zet géén `kSecAttrSynchronizable` (`RingSync.swift:242-249`), dus hij staat alleen op deze iPhone (https://developer.apple.com/documentation/security/ksecattrsynchronizable).
- `factoryReset` wist ook de sleutel in de app (`RingSync.swift:538`) en gaat alleen door bij een kloppend serienummer (`RingSync.swift:493-516`).
- De pbxproj noemt elk bronbestand apart (`project.pbxproj:13,23,57,105`). Elk nieuw Swift- of testbestand vraagt dus `xcodegen generate --spec project-ci.yml` en een commit van de pbxproj.
- Het gecommitte project is model-vrij: gemeten 0 treffers op `TorchBridge|CvaModel`. Xcode Cloud genereert opnieuw uit `project-ci.yml` (`ci_scripts/ci_post_clone.sh:35-36`).
- Xcode Cloud: elke push naar `main` = één build; het tegoed vult op 7 dec aan (`HANDOFF.md:27-30`). Daarom één push aan het eind van M1.
- Deploymentdoel iOS 17 (`project-ci.yml:13`); SDK op de Mac is iOS 27.2. Het glazen tabbalkje op iOS 26+ tekent het systeem zelf (`OHAppShell.swift:3-4`). Op 27.2 **niet nagegaan**.
- Canvasbladen laden `./support.js`, dat niet in de repo staat (`S-Vandaag.dc.html:6`). De inhoud is statische HTML met inline-stijl. Instrument Serif is de web-stand-in voor New York (`OHTheme.swift:48`).
- Privacy: een data-export bevat gezondheidsdata. `*.db` en `local/` staan in `.gitignore` (regels 4, 33). Geen materiaal van Oura; de ring op Mijn ring is getekend.

## Beginpunt (gecontroleerd in de code)

- De app start altijd `RootView` (`OuraApp.swift:1286-1289`), een licht thema met Engelse teksten.
- `Design/` staat niet in de sources (`project.yml:65-98`, `project-ci.yml:43-66`) en niet in de pbxproj (0 treffers). Nog nooit gecompileerd. `OuraCore.xcframework` ontbreekt lokaal, dus de app bouwt op deze Mac nu helemaal niet.
- OH-viewmodellen hebben verplichte velden: `OHScore` met `value`, `average` en `tone` (`OHModels.swift:18-21`), `OHNight` `:77`, `OHToday` `:101`, `OHRingState` `:153`. `OHComponents.swift:88` toont altijd "Gemiddeld \(score.average)". `OHSample` (`:163`) is de enige bron.
- Mijn ring:
  - de knoppen hebben lege standaardacties (`OHRingView.swift:6-9`);
  - de sync-knop staat uit zonder `isConnected` (`:31`);
  - de statusregel zegt "Gekoppeld · aan het meten" of "laadt op" (`:116-118`), waarden die de app niet meet;
  - de wis-bevestiging bestaat al (`:58-63`).
- Kalender- en uitlegknoppen zijn nergens aangesloten (`OHSleepView.swift:6`, `OHDayTimelineView.swift:8-9`, `OHTodayView.swift:7`).
- Losse hexkleuren buiten `OHTheme`: `OHDayTimelineView.swift:117`, `OHComponents.swift:257`, `OHRingView.swift:124,174,177-178,180,183`; fasekleuren `OHModels.swift:41-44`. Previews alleen in standaardgrootte.

### Wat al bestaat (hergebruiken, niet opnieuw bouwen)

| Nodig voor | Bestaat al | Waar |
|---|---|---|
| Dag ↔ nacht koppelen | `Summary.wakeYmd`, `days`, `night(forDay:)`, `nightlySeries` | `Models.swift:374, 392, 400, 410` |
| Fasen per 30 s | `NightRow.hypnogram` (`stages_full ?? stages`), `analysisStages`, `stagingComplete` | `Models.swift:68-75` |
| Slaapmetrics (inslaaptijd) | `Sleep.metrics` — geeft `nil` zodra één code buiten 1…4 ligt | `Reports.swift:230-234` (alleen aanroepen) |
| Hypnogram uit 5-min-blokken | stadiumvoorkeur `stages_5min` → `hypnogram`, maar `Polysomnograph.lanes` is `private` | `Reports.swift:714, 732-741` (zie stap e: kopie met tweelingnotitie) |
| Slaapscore met onderdelen | `NightRow.sleep_score` / `SleepScore` | `Models.swift:85, 121`; Rust `sleep_score.rs` |
| HRV/rusthartslag van de nacht | `NightRow.hrv_ms`, `rhr`; basis `Vitals.hrv/rhr.baseline` | `Models.swift:51, 9-21` |
| Temperatuur, SpO₂ | `NightRow.skin_temp`, `spo2_mean` | `Models.swift:52` |
| Batterij, firmware, serienummer | `Device.battery_pct`, `battery_recorded`, `firmware`, `serial` | `Models.swift:191-197` |
| Stappen/kcal per dag | `Summary.activity_daily` | `Models.swift:314` |
| Activiteiten op tijdlijn | `workouts` (alleen torch; model-vrij leeg) | `Models.swift:323` |
| Sync / laatste sync | `RingSync.run`, `lastSuccessfulSyncAt`, `busy`, `knownSerial` | `RingSync.swift:622, 317, 313, 320` |
| Export + deelvenster | `exportRawDatabase` + `DiagnosticsShare` | `RingSync.swift:442`; `OuraApp.swift:458, 743` |
| Ring wissen | `factoryReset(keyHex:confirmSerial:)` | `RingSync.swift:495` |
| Sleutel lezen | `Keychain.loadKey` | `RingSync.swift:255` |
| Laden/auto-sync/herladen | `RootView.load`, `requestAutomaticSync`, `refreshAfterSync` | `OuraApp.swift:975, 912, 907` |
| Instellingenscherm | `ProfileSettingsView` (`Form` met `Toggle`) | `ProfileSettings.swift:110, 158` |
| Testdoel | `Tests/` (model-vrij: TORCH-tests vallen weg) | `NssaCacheTests.swift:1` |

Geen Rust-wijziging nodig: geen nieuw JSON-veld en geen nieuwe score. Er zijn dus geen Rust/Python-tweelingen om bij te werken. Er is één Swift-tweeling: de stadiumvoorkeur uit `Reports.swift:732-741` wordt gekopieerd (zie stap e).

## Vaste regel: project opnieuw genereren

Elke stap die een Swift-, test- of fixturebestand **toevoegt**, draait als laatste handeling vóór de commit `xcodegen generate --spec project-ci.yml` (in `apps/ios/OuraApp`) en commit de pbxproj mee. Dat zijn stap c, e en g.

Daarna volgen drie controles:
- `grep -c "TorchBridge" project.pbxproj` = 0;
- `xcshareddata/xcodecloud/manifest.json` ongewijzigd;
- `git diff --stat` op de pbxproj toont alleen toevoegingen.

`project.yml` (torch) wordt nooit gegenereerd; de controle is daar alleen `grep -n "path: Design" project.yml`.

In golf 4 schrijft alleen **g** de pbxproj:
- f genereert in zijn worktree alleen om te bouwen en zet de pbxproj vóór zijn commit terug (`git checkout -- OuraApp.xcodeproj/project.pbxproj`);
- g rebaset na de merge van f, genereert één keer en commit de pbxproj met de testbestanden van f en g.

Stap d voegt geen bestanden toe.

## Stappen in bouwvolgorde

Legenda: **heet** = hot file; **zwaar** = gebouwd door de planner (hard).

### c0 — Rust-xcframework bouwen (lane code) — **zwaar**
- Dient: 1 (zonder deze stap bouwt de app niet).
- Opdracht: `~/.claude/regie/testslot.sh bash apps/ios/build-xcframework.sh` (zware Rust-builds voor apparaat en simulator; installeert ontbrekende iOS-targets).
- Daarna `git status apps/ios/generated`. **Is er een diff in `oura_core.swift`, `oura_coreFFI.h` of `headers/`, dan stoppen en melden**: de gecommitte bindings lopen dan achter op de Rust-kern, en dat is een eigen beslissing.
- Schrijft: niets gecommits (de xcframework is gitignored). Worktrees krijgen een symlink naar `apps/ios/OuraCore.xcframework` in de hoofdcheckout.
- Heet: nee. Hard: ja (gaat aan c vooraf, door de planner).

### b — design-system.md + referenties (lane ontwerp/content)
- Dient: 2. Ramin merkt niets in de app; wel één meetbare lat per scherm.
- Bestanden: `design-system.md` (repo-root, nieuw), `design/referenties/{vandaag,tijdlijn,slaap,ring}/REFERENTIE.md` + `referentie.png`.
- `design-system.md` begint met **"Directe fails"**:
  - een hexkleur buiten `OHTheme.swift` (grep `Color(ohHex` buiten dat bestand = 0);
  - `.bold`/`.heavy`;
  - een afstand buiten `OHSpace` (4/8/12/16/24/32, plus `page` 20);
  - een kop niet via `Font.ohSerif`; een getal zonder `.monospacedDigit()`;
  - rood buiten "Ring wissen";
  - `OHSample` buiten `#Preview`;
  - een getal zonder bronveld (zoals "Gemiddeld" zonder `average`);
  - afgekapte tekst op `accessibility5`; een tikvak < 44 pt; een icoon zonder label;
  - Oura-materiaal.

  Daarna tokens uit `OHTheme.swift`.
- Per scherm 3–8 meetbare regels, inclusief de lege toestand (bijvoorbeeld Slaap zonder fasen: geen hypnogram, wel duur en HRV).
- Referentiebeelden: `playwright screenshot --browser chromium --viewport-size "390,844" file://$PWD/docs/ontwerp-canvas/S-Vandaag.dc.html design/referenties/vandaag/referentie.png` (headless-shell in `~/Library/Caches/ms-playwright`; netwerk voor Google Fonts). De REFERENTIE.md vermeldt 390×844 en dat `support.js` ontbrak.
- Heet: nee. Tweelingen: geen. iPhone: nee. Hard: nee.

### c — Design in beide projecten + compileren (lane code) — **zwaar**
- Dient: 1. Ramin merkt niets (de oude app is ongewijzigd).
- Bestanden: **`project.yml`**, **`project-ci.yml`** (beide `- path: Design` met `excludes: [README.md]`), **`OuraApp.xcodeproj/project.pbxproj`** (gegenereerd volgens de vaste regel), `Design/*.swift` (alleen compileerfixes).
- Build: `xcodebuild -project OuraApp.xcodeproj -scheme OuraApp -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` via `testslot.sh`.
- Wacht op: c0.
- Heet: ja (projectbestanden). Hard: ja (Xcode-project). iPhone: nee.

### d — Previews nalopen, donker + grootste tekst (lane ui)
- Dient: 2. Ramin krijgt 8 screenshots met voorbeelddata.
- Bestanden: `Design/OHTheme.swift` (alle losse hexkleuren, inclusief `OHRingView.swift:180,183` en de fasekleuren, worden tokens), `OHComponents.swift`, `OHTodayView.swift`, `OHDayTimelineView.swift`, `OHSleepView.swift`, `OHRingView.swift`, `OHModels.swift`, `docs/screenshots/ontwerp/*-sample-{std,ax5}.png`.
- Per scherm `#Preview("AX5")` met `.environment(\.dynamicTypeSize, .accessibility5)`.
- Keuren via Xcode MCP `RenderPreview` (`.mcp.json`). Valt die weg, dan een XCTest met `ImageRenderer` (die test maakt dan stap e mee aan, niet d).
- Eerste keuring: `goal-designer` + `axiom:accessibility-auditor`.
- Heet: nee. Geen nieuwe bestanden, dus geen pbxproj. Hard: nee.

### e — Echte data koppelen, lege vakken eerlijk leeg (lane data)
- Dient: 3. Ramin merkt: de schermen tonen zijn eigen nachten, en vakken zonder berekening blijven leeg (vorm volgens vraag 1).
- Bestanden:
  - `Design/OHModels.swift`:
    - `OHScore.average: Int?` en `tone: OHTone?` (geen bronveld, dus `nil`);
    - optionele scores, waarden en `headline`;
    - `OHRingState` zonder `isConnected`/`isCharging`, met `isSyncing`, `batteryPercent: Int?`, `batteryRecorded: String?`, `firmware`/`serial: String?` en `hasKey`.
  - `Design/OHComponents.swift`: "Gemiddeld" alleen als `average != nil` (`:88`); zonder `tone` de neutrale kleur.
  - Views: lege toestanden.
  - Nieuw:
    - `Design/OHSummaryMapping.swift`;
    - `Design/OHLiveShell.swift` met vaste signatuur `OHLiveShell(summary: Summary, ring: RingSync, onSynced: (SyncReport)->Void, onReset: ()->Void, onUseOldDesign: ()->Void)`, nog zonder acties;
    - `Design/OHPreviewSummaries.swift` (`Summary`'s gedecodeerd uit inline JSON, voor previews: gevuld en leeg);
    - `Tests/OHSummaryMappingTests.swift`;
    - `Tests/fixtures/oh-summary-{staged,offset,partial,empty}.json` (synthetisch).
  - pbxproj volgens de vaste regel.
- Mapping-regels:
  - HRV en rusthartslag uit `night(forDay: vandaag)` (`hrv_ms`, `rhr`), niet uit `vitals.hrv.latest`. `hrvRatio` = `hrv_ms / vitals.hrv.baseline`, alleen als beide bestaan.
  - Fasen: **kopie** van de stadiumvoorkeur uit `Reports.swift:732-741`, omdat `Polysomnograph.lanes` `private` is (`:714, 732`) en `Reports.swift` hot is. De kopie is een static helper in `OHSummaryMapping.swift` met de commentaarregel `// twin of Reports.swift Polysomnograph.lanes stage choice` en een regel in Known gaps (h0).
  - Een segment begint op `stages_t0_unix` (of `start_unix`) en ligt in [0,1]. Codes buiten 1…4 en de tijd vóór `t0` blijven gat.
  - Inslaaptijd via `Sleep.metrics` (`Reports.swift:232`). Die geeft `nil` bij een deels gestagede nacht, dus het vak blijft dan leeg.
- Test eerst (rood): de asserts uit klaar-als 3, plus `average == nil` en `tone == nil`.
- Meten (vraag 4 = A):
  - een scratchscript in de scratchpad (eigen `Cargo.toml` met path-dependency op `crates/oura-core`) roept `summary_json` aan op het geëxporteerde bestand in `local/`;
  - telt per veld de gevulde nachten;
  - **niets gecommit**, alleen de aantallen gaan naar `HANDOFF.md`.
- Heet: nee (alle bestanden < 300 regels; `Reports.swift` niet geschreven). Tweeling: Swift-kopie van de stadiumvoorkeur, genoteerd. Hard: nee. iPhone: alleen bij vraag 4 (een export, geen ringactie).

### f — Knoppen aan bestaande functies (lane code) — **zwaar**
- Dient: 4 en 2. Ramin merkt: Synchroniseren en Exporteren werken, Wissen vraagt eerst bevestiging met het serienummer, en Back-up volgt vraag 3.
- Bestanden: `Design/OHLiveShell.swift`, `Design/OHRingView.swift`, `Design/OHTodayView.swift`, nieuw `Tests/OHRingActionsTests.swift` (pbxproj **niet** committen; dat doet g), `docs/screenshots/ontwerp/*-live-{std,ax5}.png`.
- `OHRingView`:
  - sync-knop uit alleen bij `ring.busy` of geen sleutel; de `isConnected`-voorwaarde (`:31`) gaat weg;
  - statusregel "Gekoppeld · aan het meten/laadt op" (`:116-118`) vervangen door "Bezig met synchroniseren" (alleen bij `busy`), anders de laatste sync;
  - wissen uit bij geen sleutel, `busy` of geen `knownSerial`; de bevestiging noemt het serienummer;
  - rij "Oude weergave" via `onUseOldDesign`.
- De sleutel alleen via `Keychain.loadKey()` doorgeven, nooit tonen of loggen. `factoryReset` alleen vanuit de bevestiging.
- Na f: de previews opnieuw renderen met `OHPreviewSummaries` (gevuld en leeg), standaard en AX5. `goal-designer` + `axiom:accessibility-auditor` keuren opnieuw.
- Heet: nee. Hard: ja (dichtbij koppelsleutel en reset). Ring: **nooit** testen op de echte ring.

### g — Schakelaar oud/nieuw (lane ui)
- Dient: 5. Ramin merkt: in Profiel de regel "Nieuw ontwerp (proef)"; de oude weergave blijft standaard.
- Bestanden:
  - **`OuraApp.swift`**: in `RootView` `@AppStorage("ui.newDesign") = false`, en in `body` `OHLiveShell(...)` in plaats van `content(s)`, zodat laden, auto-sync en sheets blijven werken;
  - `ProfileSettings.swift` (`Toggle`);
  - nieuw `Tests/DesignSwitchTests.swift`;
  - **pbxproj**: na rebase op f, één keer genereren voor de testbestanden van f en g.
- Bewijs ook: simulatorstart met `-ui.newDesign NO` en `-ui.newDesign YES` via `testslot.sh`.
- Heet: ja (`OuraApp.swift`, 1.290 regels; projectbestand). Hard: nee. iPhone: in stap h.

### h0 — Notities (lane content)
- Dient: 6 en de lijst bij 3.
- Bestanden: `docs/clients-web-and-ios.md` (Known gaps iOS-only: vier schermen, schakelaar, tweeling-kopie stadiumvoorkeur), `HANDOFF.md` (wat gedaan is, ontbrekende velden met aantallen, open voor web).
- Wacht op: e, f, g. Heet: nee. Hard: nee.

Daarna: `goal-final-auditor` over alle stappen, één volledige testrun via `testslot.sh`, dan stap h van Ramin (push, build aan groep Intern, beide weergaven proberen).

## Stappenkaart (parallel)

| Stap | Schrijft | Wacht op | Lane | Golf |
|---|---|---|---|---|
| c0 | niets gecommits (xcframework, gitignored) | — | C (code) | 1 |
| b | `design-system.md`, `design/referenties/*` | — | O (ontwerp) | 1 |
| c | **`project.yml`**, **`project-ci.yml`**, **`project.pbxproj`**, `Design/*` (fixes) | c0 | C | 2 |
| d | `Design/*`, `docs/screenshots/ontwerp/*-sample-*` | b, c | U (ui) | 3 |
| e | `Design/*` + 3 nieuwe, `Tests/OHSummaryMapping*`, `Tests/fixtures/oh-*`, **`project.pbxproj`** | d | D (data) | 4 |
| f | `Design/OHLiveShell.swift`, `OHRingView.swift`, `OHTodayView.swift`, `Tests/OHRingActionsTests.swift`, `docs/screenshots/ontwerp/*-live-*` | e | C | 5 |
| g | **`OuraApp.swift`**, `ProfileSettings.swift`, `Tests/DesignSwitchTests.swift`, **`project.pbxproj`** (na merge f) | e, f (alleen voor de pbxproj) | U | 5 |
| h0 | `docs/clients-web-and-ios.md`, `HANDOFF.md` | e, f, g | T (content) | 6 |

- Hot-file-slots: de projectbestanden schrijven alleen c, e en g (achter elkaar). `OuraApp.swift` schrijft alleen g. `Reports.swift`, `oura-summary/src/lib.rs` en `app.js` worden niet geschreven.
- Golf 1 (c0 ∥ b) en golf 5 (f ∥ g, waarbij g de pbxproj pas na de merge van f schrijft) draaien in eigen worktrees, met een symlink naar de xcframework.
- Zware runs één tegelijk via `~/.claude/regie/testslot.sh`: c0 (Rust), de builds van c, e, f en g na elkaar. b rendert alleen 4 PNG's.
- Release-lane: alleen Ramin (stap h).

## Vragenpagina voor Ramin

**1. Scores die nog niet bestaan op Vandaag.** Herstel- en activiteitsscore rekent de app nog niet uit (komt in M2). De slaapscore alleen als de ring zelf slaapfasen levert. Een "gemiddeld"-waarde onder een score is er nergens.
- A — Lege ring met "—" en eronder "volgt later". *Advies:* het scherm houdt de vorm van het canvas en je ziet eerlijk wat nog komt; M2 vult het zonder herbouw. Voorbeeld: drie ringen, alleen "Slaap 81" gevuld (zonder "Gemiddeld"), de andere twee grijs met "—".
- B — Ontbrekende scores weglaten. Voorbeeld: alleen één ring "Slaap 81" bovenaan.
- C — Ringen voorlopig vervangen door de vitale waarden. Voorbeeld: bovenaan "HRV 84 ms · 8% onder je basis".

**2. De zin bovenaan Vandaag** (in het ontwerp: "Rustig aan vandaag"). Een advies rekent de app nog niet uit.
- A — Een feitelijke zin uit je cijfers, zonder advies. *Advies:* dan klopt elk woord. Voorbeeld: "8u 11m geslapen · HRV 8% onder je basis".
- B — Geen zin tot M2. Voorbeeld: bovenaan alleen de datum.

**3. "Sleutel back-uppen" op Mijn ring.** De app bewaart je sleutel nu alleen op deze iPhone, niet in iCloud.
- A — Knop zichtbaar uit, met de regel "Je sleutel staat veilig op deze iPhone; back-up via iCloud volgt later". *Advies:* zo vraagt de opdracht het ("of zichtbaar uitgeschakeld"), en je hebt de sleutel al zelf bewaard.
- B — Nu bouwen: na jouw tik een kopie in je iCloud-sleutelhanger. Voorbeeld: op een nieuwe iPhone staat de sleutel er na inloggen vanzelf. Risico: je sleutel verlaat dit toestel.
  - *Technische noot bij B:* `Keychain.clearKey` en `loadKey` (`RingSync.swift:251-268`) zoeken zonder `kSecAttrSynchronizable`. Die moeten dan `kSecAttrSynchronizableAny` meekrijgen, anders laat "wissen" een iCloud-kopie staan of vindt "laden" hem niet.

**4. Meten welke waarden jouw ring echt levert** (na je ringtest). Dat gaat alleen met jouw data.
- A — Je tikt in de oude weergave op Your ring → "Export data" en AirDropt het bestand naar de Mac. Een los script op de Mac telt alleen welke velden gevuld zijn. Het bestand blijft in een map die nooit gecommit wordt, en het script wordt ook niet gecommit. *Advies:* dan is de lijst ontbrekende velden gemeten, niet geraden. Voorbeeld uitkomst: "14 nachten, 0 met slaapfasen → slaapscore blijft leeg".
- B — Niet delen. We bouwen op de code, en jij controleert in stap h op je iPhone wat leeg blijft.

## Technische keuzes (zelf gemaakt, terug te draaien)

1. Het nieuwe ontwerp draait **binnen `RootView`**: `OHLiveShell` vervangt alleen `content(s)`, zodat laden, auto-sync en sheets één keer bestaan.
2. De schakelaar is `@AppStorage("ui.newDesign")`, standaard uit. Aan/uit in Profiel, terug via "Oude weergave" op Mijn ring. Nederlands label.
3. De mapping, de live-shell en de previewdata staan in `Design/`, zodat ze in beide specs vallen; `README.md` wordt uitgesloten.
4. De stadiumvoorkeur wordt **gekopieerd** in plaats van uit `Reports.swift` gehaald. Dat spaart een hot-file-slot, met een tweelingnotitie in code en in Known gaps. Terugdraaien kan later door de helper uit `Reports.swift` te halen.
5. Kalenderknoppen en "Uitleg herstel" worden verborgen tot er een bestemming is; tikken op een dag in de weekstrook scrollt naar die dag.
6. Op Mijn ring:
   - geen hardgecodeerde "Ring 5" (firmware of serienummer);
   - batterij uit de laatste sync, met tijdstip;
   - "verbonden" en "opladen" vervallen, want de app meet ze niet live;
   - "Bezig met synchroniseren" alleen bij `ring.busy`.
7. Simulatorbuilds met `CODE_SIGNING_ALLOWED=NO`; `build_run.sh` (oud bundle-ID) wordt niet gebruikt.
8. Alle losse hexkleuren worden tokens in `OHTheme` (stap d).
9. Testfixtures en previewdata zijn synthetisch. Echte data alleen in `local/`, nooit in tests of commits.

## Backlog (buiten M1)

- Eigen herstel- en activiteitsscore, signaal-staging op model-vrij iOS (M2).
- Kalender- en uitleg-bestemmingen in de nieuwe weergave.
- iCloud-back-up van de sleutel (als vraag 3 = A).
- Stadiumvoorkeur als gedeelde helper uit `Reports.swift` (opruimen van de tweeling).
- Web in de nieuwe stijl (M3).
- `build_run*.sh` bundle-ID.

## Risico's

- **De xcframework-build herschrijft de gecommitte bindings.** Bij een diff in `apps/ios/generated` stopt c0 en meldt het; c begint dan niet.
- **Ring 5 levert misschien geen eigen slaapfasen.** Dan blijven Slaap en de slaapring op model-vrij iOS leeg; de lege toestand staat in REFERENTIE slaap. De echte oplossing is M2.
- **xcodegen kan `xcshareddata` herschrijven.** Elke generatiestap controleert de diff en stopt bij een afwijking.
- **Twee worktrees die de pbxproj schrijven.** Afgevangen met de vaste regel: in golf 5 alleen g, na de merge van f.
- **Xcode MCP `RenderPreview`** vereist een open Xcode. Terugval is een `ImageRenderer`-test zonder glazen tabbalkje; dat bekijk je in de simulator.
- **Hot file `OuraApp.swift`**: een fout in de `body`-wissel raakt de oude app. De standaard blijft uit, en `DesignSwitchTests` + de start met `-ui.newDesign NO` bewijzen dat de oude weergave ongewijzigd start.
- **Apart fix-doel "fix-laadscherm" op main** (het laadscherm bij het starten heeft geen weg naar het sync-venster) kan `OuraApp.swift` raken vóór stap g. g rebaset daarop en neemt de wijziging in de `body`-wissel mee: het laadscherm blijft in beide weergaven gelijk.
- **Wissen**: zonder sleutel, tijdens sync of zonder `knownSerial` blijft de knop uit. Er komt geen enkele test op de echte ring.
- **Xcode Cloud-tegoed**: één push aan het eind (stap h). Faalt die build, dan is er weinig ruimte voor herhalen vóór 7 dec.
