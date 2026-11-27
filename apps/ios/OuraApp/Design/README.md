# Nieuw ontwerp (sfeervolle richting)

SwiftUI-versie van de vier gekozen schermen uit het canvas
"Open Health – iOS en webdashboard": Vandaag, Tijdlijn, Slaap en Mijn ring.

**Status: nog niet gecompileerd en nog niet in de build.** De bestanden staan niet in
`project.yml` of `project-ci.yml`, dus Xcode en Xcode Cloud negeren ze. De bestaande app
blijft precies werken zoals nu.

## Bestanden

| Bestand | Inhoud |
| --- | --- |
| `OHTheme.swift` | Kleuren, afstanden, achtergronden, kaarten, glazen knoppen, opmaak van tijden |
| `OHModels.swift` | Eenvoudige view-modellen plus voorbeelddata (`OHSample`) |
| `OHComponents.swift` | Scorering, basislijnbalk, hero, hypnogram, fasebalk, tijdlijnregel |
| `OHTodayView.swift` | Vandaag |
| `OHDayTimelineView.swift` | Tijdlijn |
| `OHSleepView.swift` | Slaap |
| `OHRingView.swift` | Mijn ring |
| `OHAppShell.swift` | `TabView` met de vier tabs |

Alles heeft het voorvoegsel `OH`, zodat niets botst met bestaande types zoals `Hypnogram`,
`RootView` of SwiftUI's eigen `TimelineView`. Doel: iOS 17, zoals de rest van het project.
Elk scherm heeft een `#Preview` met voorbeelddata.

## Inbouwen (volgende stappen)

1. Voeg de map toe aan `sources` in **beide** projectbestanden:
   ```yaml
   - path: Design
   ```
   Daarna `xcodegen generate --spec project.yml` (lokaal) en dezelfde wijziging in het
   gecommitte model-vrije project voor Xcode Cloud.
2. Bouw, los compileerfouten op en bekijk de previews in licht en donker en met de
   grootste tekstgrootte.
3. Schrijf een mapping van `Summary` naar `OHToday`, `OHNight`, `OHTimelineDay` en
   `OHWeekDay`, en van de ringstatus in `RingSync` naar `OHRingState`.
4. Koppel de acties: synchroniseren, sleutel back-uppen (Keychain), ruwe data exporteren
   en ring wissen (`factoryReset`). Gebruik bestaande functies; voeg geen nieuwe
   functionaliteit toe zonder overleg.
5. Vervang daarna pas `RootView` door `OHAppShell`, achter een schakelaar zodat de oude
   weergave terug kan.

## Ontwerpregels

- Donker ontwerp; `OHAppShell` zet `.preferredColorScheme(.dark)`.
- Eén accent per betekenis: groenblauw = goed, amber = let op, rood alleen voor wissen.
- Koppen in de serif van het systeem (New York) via `Font.ohSerif`, de rest in
  tekststijlen van het systeem; cijfers met `.monospacedDigit()`.
- Afstanden alleen uit `OHSpace` (4, 8, 12, 16, 24, 32).
- Tikvakken minstens 44 pt; elk icoon zonder tekst heeft een `accessibilityLabel`.
- De ring op Mijn ring is getekend. Gebruik geen afbeeldingen of iconen uit de
  Oura-app.
