# PC Tweaks System - Brugervejledning (Dansk)

Et Windows-program der registrerer dine PC-komponenter og viser de bedste optimeringer for din specifikke hardware.

## Funktioner

- **Hardware-registrering**: Finder automatisk CPU, GPU, RAM, lagerenheder og bundkort
- **Komponent-specifikke tweaks**: Viser optimeringer tilpasset din specifikke hardware (Intel/AMD CPU, NVIDIA/AMD GPU osv.)
- **Basale PC-tweaks**: Generelle optimeringstips der virker på alle systemer
- **Kategoriserede anbefalinger**: Tweaks organiseret efter påvirkning og kategori (Performance, Gaming, Stabilitet osv.)

## Installation

### Mulighed 1: Brug den færdige .exe fil

1. Download `PC_Tweaks.exe` fra releases
2. Kør programmet (ingen Python-installation nødvendig)
3. Kør helst som Administrator for bedste hardware-registrering

### Mulighed 2: Kør fra kildekode (kræver Python)

1. Installer Python 3.8 eller nyere
2. Klon dette repository
3. Installer afhængigheder:
   ```bash
   pip install -r requirements.txt
   ```
4. Kør programmet:
   ```bash
   python main.py
   ```

## Systemkrav

- **Operativsystem**: Windows 7 eller nyere (Windows 10/11 anbefales)
- **Python** (kun for kildekode): Python 3.8+
- **Administrator-rettigheder**: Nogle hardware-registreringsfunktioner virker bedst med admin-rettigheder

## Sådan bruges programmet

1. Kør `PC_Tweaks.exe` (eller `python main.py` hvis du kører fra kildekode)
2. Programmet registrerer automatisk dine hardware-komponenter
3. Gennemse den viste hardware-information
4. Gennemse de kategoriserede tweaks:
   - **Basale PC Tweaks**: Gælder for alle systemer
   - **CPU Tweaks**: Specifikke for Intel/AMD
   - **GPU Tweaks**: Specifikke for NVIDIA/AMD
   - **RAM/Hukommelses Tweaks**: Optimer din RAM
   - **Lagerenheds Tweaks**: SSD/HDD optimeringer
   - **Windows Tweaks**: Windows-specifikke indstillinger

5. Følg instruktionerne for de tweaks du vil anvende

## Registrerede Hardware-komponenter

Programmet registrerer:
- **CPU**: Mærke, model, kerner, tråde, frekvens
- **GPU**: Grafikkort model, hukommelse, driver version
- **RAM**: Samlet hukommelse, tilgængelig hukommelse, brugsprocentdel
- **Lagerenheder**: Alle drev med kapacitet og ledig plads
- **Bundkort**: Producent og model (kun Windows)
- **OS**: Operativsystem version

## Tweak Kategorier

Tweaks er organiseret efter:
- **Påvirkningsniveau**: Høj, Medium, Lav
- **Kategori**: Performance, Gaming, Stabilitet, Strømbesparelse, Privatliv osv.
- **Komponent-type**: CPU, GPU, RAM, Lager, Windows

## Sikkerhedsmeddelelse

- **Opret altid et systemgendannelsespunkt før du laver systemændringer**
- Nogle tweaks kræver BIOS/UEFI adgang - modificer kun hvis du er komfortabel med det
- Administrator-rettigheder kan være nødvendige for visse tweaks
- Dette værktøj giver kun anbefalinger - du beslutter hvilke du vil implementere

## Byg din egen .exe fil

Se [BUILD_INSTRUCTIONS.md](BUILD_INSTRUCTIONS.md) for detaljeret vejledning om hvordan du bygger din egen executable fil.

Kort version:
1. Installer afhængigheder: `pip install -r requirements.txt`
2. Byg med PyInstaller: `pyinstaller PC_Tweaks.spec`
3. Find executable i `dist\PC_Tweaks.exe`

Eller brug build scriptet:
```bash
build.bat
```

## Ofte Stillede Spørgsmål

### Hvorfor registreres min hardware ikke korrekt?
- Kør programmet som Administrator for fuld hardware-registrering
- Nogle funktioner kræver WMI (inkluderet i Windows)

### Er det sikkert at bruge disse tweaks?
- Alle tweaks er standard optimeringer brugt af PC-entusiaster
- Opret altid et systemgendannelsespunkt først
- Anvend kun tweaks du forstår

### Kan jeg bruge dette på Windows 11?
- Ja, programmet virker på Windows 7, 8, 10 og 11

### Hvorfor er .exe filen så stor?
- PyInstaller bundter Python og alle afhængigheder i én fil
- Dette gør det muligt at køre uden Python-installation
- Typisk størrelse: 10-20 MB

### Min antivirus markerer .exe filen
- Dette er en falsk positiv (almindeligt med PyInstaller)
- Byg selv fra kildekode for at verificere sikkerheden
- Eller tilføj en undtagelse i dit antivirus program

## Bidrag

Bidrag er velkomne! Du kan:
- Tilføje nye tweaks til `tweaks_database.py`
- Forbedre hardware-registrering i `hardware_detector.py`
- Forbedre brugergrænsefladen
- Rapportere bugs eller foreslå funktioner

## Ansvarsfraskrivelse

Dette værktøj giver optimeringsanbefalinger. Udviklerne er ikke ansvarlige for eventuelle problemer der opstår ved anvendelse af disse tweaks. Lav altid backup af dine data og opret gendannelsespunkter før du laver systemændringer.

## Support

Hvis du har problemer:
1. Check at alle afhængigheder er installeret
2. Kør som Administrator
3. Opret et issue på GitHub med detaljer om problemet

## Licens

Dette projekt er open source. Brug på eget ansvar.
