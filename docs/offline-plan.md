# Plan: volledig offline, zonder Oura-modellen

Doel: alles wat de app toont wordt op het toestel berekend uit ruwe ringdata, met eigen
code en eigen modellen. Geen Oura-app, geen cloud, geen abonnement, geen `.pt`/`.ptl`
van Oura en geen libtorch in de app.

## Uitgangspunt in de code

- `oura-summary::build_summary()` is het gedeelde rekenhart voor iOS en web.
- Modellen komen binnen via de `ModelRunner`-trait. iOS gebruikt nu `NoModelRunner`.
- Voorstel: een nieuwe `OpenModelRunner` in puur Rust (nieuw crate `open-models`).
  Daarmee krijgen iOS en web dezelfde uitkomsten en blijft de app klein.

## Laag 0: werkt al (geport en getest)

| Onderdeel | Methode | Bron |
| --- | --- | --- |
| HRV | RMSSD = wortel van gemiddelde gekwadrateerde verschillen tussen opeenvolgende IBI's | `oura-analysis::hrv` |
| Persoonlijke basislijn | asymmetrisch voortschrijdend gemiddelde dat met de tijd trager wordt | `oura-analysis::baseline` |
| Huidtemperatuur per nacht | mediaan van 7 samples, venster van 30 min, afwijking t.o.v. basislijn | `oura-analysis::temperature` |
| SpO2 | `a + b·R + c·R²` (per apparaat te kalibreren) | `oura-analysis::spo2` |
| Stappen, afstand, kcal, VO2max | Schofield BMR, Jackson VO2max | `oura-analysis::metabolic` |
| Slaapduur, efficiëntie, inslaaptijd | telt 30 s-epochs uit een fase-reeks | `oura-analysis::sleep` |
| Slaapschuld | 14 dagen t.o.v. behoefte | `oura-analysis::sleep_debt` |

De slaapcijfers hebben een fase-reeks nodig. Die komt uit laag 1.

## Laag 1: slaapfasen zonder Oura-model

**v0, fasen van de ring zelf.** De ring stuurt events `0x5A sleep_phase_data` en
`0x4E sleep_phase_details`. Eerst uitzoeken (na het koppelen) of de Ring 5 die levert en
hoe compleet ze zijn. Zo ja: decoderen en als fase-reeks in `oura-analysis::sleep`
stoppen. Dat geeft direct een hypnogram zonder enig model. Nog niet geverifieerd.

**v1, eigen classifier.** Per epoch van 30 s, vier klassen (wakker, licht, diep, REM).

- Invoer: gecorrigeerde IBI's (`0x60`), beweging (`0x72`, zes statistieken),
  vingertemperatuur (`0x75`), tijd sinds inslapen.
- Features per epoch plus vensters eromheen (1, 5, 15 min): gemiddelde hartslag, RMSSD,
  SDNN, verhouding lage/hoge frequentie, ademfrequentie uit de IBI-golf, bewegingsmaat,
  temperatuurtrend, klokpositie in de nacht.
- Model: gradient boosted trees. Draait als gewone Rust-code, geen ML-runtime nodig.
- Trainingsdata: openbare slaaplab-datasets met hartslag en beweging naast
  polysomnografie (bijvoorbeeld op PhysioNet). Licenties per dataset controleren.
- Nabewerking: korte uitschieters gladstrijken, daarna dezelfde 5-minutenweergave.
- Verwachting: fasen uit hartslag en beweging blijven een schatting. Wakker/slaap is
  betrouwbaar, het onderscheid licht/diep/REM minder. Dat tonen we eerlijk in de app.

## Laag 2: eigen scores (open en uitlegbaar)

Geen kopie van Oura's scores, wel dezelfde soort ingrediënten.

- **Slaap (0–100):** duur t.o.v. behoefte, efficiëntie, inslaaptijd, onrust, aandeel
  diep en REM, regelmaat van bedtijd. Elk onderdeel krijgt een open curve en gewicht.
- **Herstel (0–100):** afwijking van je eigen basislijn voor nachtelijke HRV,
  rusthartslag en temperatuur, plus slaapschuld en belasting van de vorige dag.
- **Activiteit (0–100):** actieve minuten per intensiteit (MET), spreiding over de dag,
  7-daagse belasting.
- Gewichten staan in één leesbaar bestand. De app laat per score zien wat hem omhoog of
  omlaag trok.

## Laag 3: wat nog ontbreekt

- **Ademfrequentie:** IBI's op 4 Hz herbemonsteren, banddoorlaat 0,1–0,4 Hz, piek zoeken.
- **Workoutherkenning:** regels op MET en hartslag (aaneengesloten inspanning, minimale
  duur). Geen temperatuurregel: die gaf eerder valse "zwem"-meldingen. Type workout
  kiest de gebruiker zelf; automatisch typeren is later.
- **Cardiovasculaire leeftijd:** niet nabouwen. VO2max-schatting blijft.

## Research bench

Doel: elke berekening is na te rekenen en versies zijn te vergelijken.

- Invoer: de bestaande export van ruwe ringdata (SQLite) of de research-export (CSV).
- `oura bench <metriek>` draait een berekening op een vaste dataset en schrijft de
  uitkomst plus versie weg.
- Vaste testnachten in de repo (geanonimiseerd) met verwachte uitkomsten, als
  regressietest in CI.
- Vergelijkingen: v0 tegen v1 voor slaapfasen (overeenstemming per epoch, kappa),
  en eigen scores tegen je eigen historie.
- Het webdashboard krijgt een paneel "Research bench": per onderdeel methode, signalen
  en status, met een knop om ruwe data te exporteren.

## Volgorde

1. Ring wissen en koppelen met de eigen app, sleutel veiligstellen.
2. `OpenModelRunner` met laag 0 plus v0-fasen (als de ring ze levert).
3. Eigen scores (laag 2) in `oura-summary`, tonen in iOS en web.
4. Research bench en testnachten.
5. Eigen classifier (v1) trainen, vergelijken met v0, pas daarna inschakelen.
6. Ademfrequentie en workoutherkenning.

Elke stap raakt beide clients: zie `docs/clients-web-and-ios.md`.
