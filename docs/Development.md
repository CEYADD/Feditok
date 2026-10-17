# Guida allo Sviluppo

## Prerequisiti
- Flutter SDK (versione 3.13+ raccomandata)
- Dart SDK 3.x
- Git LFS (per file binari di release e asset di grandi dimensioni)
- Android SDK e/o Xcode (per testare su emulatori o dispositivi fisici)

## Setup del Progetto

1. **Clona la repository:**
   ```bash
   git clone https://github.com/PiedinoTimido/Feditok.git
   cd Feditok
   ```

2. **Installa le dipendenze:**
   ```bash
   flutter pub get
   ```

3. **Verifica l'analisi statica del codice:**
   ```bash
   flutter analyze
   ```

4. **Avvia l'applicazione:**
   ```bash
   flutter run
   ```

## Standard di Sviluppo e Linee Guida
- Seguire le convenzioni di stile Dart (`dart format`, `dart analyze`).
- Utilizzare Conventional Commits per i messaggi di commit (`feat: ...`, `fix: ...`, `style: ...`, `docs: ...`).
- Garantire il rispetto delle linee guida di accessibilità WCAG (aggiunta di `semanticLabel` per immagini, contrasto cromatico e supporto a screen reader).
