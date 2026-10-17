# Accessibility (a11y) & WCAG Audit: FediverseAuthScreen

**Target Scope**: `lib/screens/auth/fediverse_auth_screen.dart` (`FediverseAuthScreen`)  
**File Path**: `d:\Feditok\lib\screens\auth\fediverse_auth_screen.dart`  
**WCAG Standard**: WCAG 2.1 / 2.2 Level AA  
**Platform Guidelines**: Android (48x48 dp), iOS (44x44 dp)

---

## Executive Summary

`FediverseAuthScreen` enables federated authentication through ActivityPub instances (Mastodon, Pixelfed, etc.) via dynamic OAuth registration and deep link callbacks. Key accessibility issues found include absence of live region announcements for asynchronous connection progress and failure states, insufficient color contrast on loading subtext inside the action button, and missing semantic roles for progress indicators and headings.

---

## Findings by Severity

### 1. High Severity

#### [HIGH-01] Missing Live Region for Dynamic OAuth Status and Error Messages
- **File**: `d:\Feditok\lib\screens\auth\fediverse_auth_screen.dart`
- **Line(s)**: 209–228, 270–279
- **WCAG Guideline**: WCAG 4.1.3 Status Messages (Level AA)
- **Defect**: During dynamic OAuth registration and token exchange, `_statusMessage` transitions through multiple phases ("Registrazione OAuth dinamica...", "Apertura pagina di autorizzazione...", "Scambio token...", "Recupero dati profilo..."). None of these dynamic status updates are announced to screen readers. If an error occurs, `_errorMessage` appears silently. Users reliant on screen readers have no perception of the multi-step handshake.
- **Code Fix**:
```dart
// Wrap status message in Semantics live region (inside button or dedicated status box):
if (_statusMessage != null)
  Semantics(
    container: true,
    liveRegion: true,
    child: Text(
      _statusMessage!,
      style: const TextStyle(fontSize: 13, color: Colors.white),
      textAlign: TextAlign.center,
    ),
  ),

// Wrap error message in Semantics live region:
if (_errorMessage != null)
  Semantics(
    container: true,
    liveRegion: true,
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const ExcludeSemantics(child: Icon(Icons.error_outline, color: Colors.redAccent, size: 20)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
            ),
          ),
        ],
      ),
    ),
  ),
```

---

### 2. Medium Severity

#### [MED-01] Low Color Contrast on Button Status Subtitle Text
- **File**: `d:\Feditok\lib\screens\auth\fediverse_auth_screen.dart`
- **Line(s)**: 271–278
- **WCAG Guideline**: WCAG 1.4.3 Contrast (Minimum) (Level AA)
- **Defect**: The status text inside the button uses `color: Colors.white70` (70% opacity white) over the primary button background (`#6C5CE7`). The effective contrast ratio is approximately **3.4:1**, failing the WCAG AA minimum threshold of **4.5:1** for normal text (12sp).
- **Code Fix**:
```dart
// Replace Colors.white70 with solid Colors.white:
Text(
  _statusMessage!,
  style: const TextStyle(
    fontSize: 13,
    color: Colors.white, // Ensures 4.88:1 contrast ratio against #6C5CE7
    fontWeight: FontWeight.w500,
  ),
  textAlign: TextAlign.center,
),
```

#### [MED-02] Missing Semantics on CircularProgressIndicator
- **File**: `d:\Feditok\lib\screens\auth\fediverse_auth_screen.dart`
- **Line(s)**: 261–268
- **WCAG Guideline**: WCAG 1.1.1 Non-text Content (Level A), WCAG 4.1.2 Name, Role, Value (Level A)
- **Defect**: The loading spinner within `ElevatedButton` has no `semanticsLabel` or `semanticsValue`, rendering it invisible to screen readers while disabling the button.
- **Code Fix**:
```dart
CircularProgressIndicator(
  strokeWidth: 2,
  color: Colors.white,
  semanticsLabel: 'Connessione e autorizzazione in corso',
),
```

#### [MED-03] Missing Heading Semantics on Section Title
- **File**: `d:\Feditok\lib\screens\auth\fediverse_auth_screen.dart`
- **Line(s)**: 193–197
- **WCAG Guideline**: WCAG 1.3.1 Info and Relationships (Level A), WCAG 2.4.6 Headings and Labels (Level AA)
- **Defect**: The title text `'ActivityPub'` acts as the screen's main section header but lacks `Semantics(header: true)`.
- **Code Fix**:
```dart
Semantics(
  header: true,
  child: Text(
    'ActivityPub',
    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
  ),
),
```

---

### 3. Low Severity

#### [LOW-01] Decorative Prefix Icon in Instance Input Field
- **File**: `d:\Feditok\lib\screens\auth\fediverse_auth_screen.dart`
- **Line(s)**: 236
- **WCAG Guideline**: WCAG 1.1.1 Non-text Content (Level A)
- **Defect**: `Icons.hub_outlined` is decorative and should be hidden from assistive navigation.
- **Code Fix**:
```dart
prefixIcon: const ExcludeSemantics(child: Icon(Icons.hub_outlined)),
```

---

## Automated Accessibility Testing Checklist

```dart
testWidgets('FediverseAuthScreen meets accessibility guidelines', (WidgetTester tester) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
      child: const MaterialApp(home: FediverseAuthScreen()),
    ),
  );

  await expectLater(tester, meetsGuideline(textContrastGuideline));
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
});
```
