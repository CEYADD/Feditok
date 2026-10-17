# Accessibility (a11y) & WCAG Audit: CameraScreen

**Target Scope**: `lib/screens/home/feed/camera_screen.dart` (`CameraScreen`, `UploadDetailsModal`)  
**File Path**: `d:\Feditok\lib\screens\home\feed\camera_screen.dart`  
**WCAG Standard**: WCAG 2.1 / 2.2 Level AA  
**Platform Guidelines**: Android (48x48 dp), iOS (44x44 dp)

---

## Executive Summary

`CameraScreen` implements full-screen camera preview capture, video recording toggle, and metadata collection (title, description, tagged usernames) via `UploadDetailsModal`. The most critical finding is the implementation of the primary recording shutter control via an unlabelled, non-focusable `GestureDetector`, which renders camera recording completely inaccessible to screen reader and keyboard navigation users.

---

## Findings by Severity

### 1. High Severity

#### [HIGH-01] Shutter Button Implemented via Unlabelled, Non-Focusable GestureDetector
- **File**: `d:\Feditok\lib\screens\home\feed\camera_screen.dart`
- **Line(s)**: 95–106
- **WCAG Guideline**: WCAG 4.1.2 Name, Role, Value (Level A), WCAG 2.1.1 Keyboard (Level A), WCAG 2.4.7 Focus Visible (Level AA)
- **Defect**: The camera capture button is implemented using a raw `GestureDetector` wrapping a `CircleAvatar`.
  1. It lacks `Semantics(button: true)`. Screen readers do not announce it as a button.
  2. It has no `label` or `hint` conveying whether tapping will begin or stop video recording.
  3. It lacks a `FocusNode` and keyboard listener; hardware keyboard or switch device users cannot tab to the button or activate it with `Enter` or `Space`.
- **Code Fix**:
```dart
// Replace lines 95-106 in lib/screens/home/feed/camera_screen.dart:
Semantics(
  button: true,
  label: _isRecording ? 'Interrompi registrazione video' : 'Avvia registrazione video',
  hint: 'Tocca due volte per attivare o disattivare la registrazione',
  child: InkWell(
    onTap: _toggleRecord,
    customBorder: const CircleBorder(),
    child: CircleAvatar(
      radius: 36,
      backgroundColor: _isRecording ? Colors.red : Colors.white,
      child: ExcludeSemantics(
        child: Icon(
          _isRecording ? Icons.stop : Icons.videocam,
          color: _isRecording ? Colors.white : Colors.black,
          size: 32,
        ),
      ),
    ),
  ),
),
```

---

### 2. Medium Severity

#### [MED-01] Missing Tooltip / Label on Add Tag IconButton in Upload Modal
- **File**: `d:\Feditok\lib\screens\home\feed\camera_screen.dart`
- **Line(s)**: 227–230
- **WCAG Guideline**: WCAG 1.1.1 Non-text Content (Level A), WCAG 4.1.2 Name, Role, Value (Level A)
- **Defect**: The tag addition `IconButton` uses `Icons.add_circle` but provides no `tooltip`. Screen reader users hear only "Pulsante" next to the text input.
- **Code Fix**:
```dart
IconButton(
  icon: const Icon(Icons.add_circle, color: Colors.purpleAccent, size: 32),
  tooltip: 'Aggiungi tag persona',
  onPressed: _addTag,
),
```

#### [MED-02] Missing Delete Action Label on Tag Chips
- **File**: `d:\Feditok\lib\screens\home\feed\camera_screen.dart`
- **Line(s)**: 239–245
- **WCAG Guideline**: WCAG 4.1.2 Name, Role, Value (Level A)
- **Defect**: The `Chip` widget providing `onDeleted` does not specify `deleteButtonTooltipMessage`. Screen readers may announce only a generic close symbol without context.
- **Code Fix**:
```dart
Chip(
  label: Text('@$tag'),
  deleteButtonTooltipMessage: 'Rimuovi tag @$tag',
  onDeleted: () {
    setState(() => _taggedUsernames.remove(tag));
  },
),
```

#### [MED-03] Missing Live Region Announcement for Recording Status
- **File**: `d:\Feditok\lib\screens\home\feed\camera_screen.dart`
- **Line(s)**: 48–62
- **WCAG Guideline**: WCAG 4.1.3 Status Messages (Level AA)
- **Defect**: When recording starts or stops, blind users rely on auditory or screen reader feedback to know recording has engaged. Currently, the state flips silently.
- **Code Fix**:
```dart
// Announce status change via a live region in the tree:
Semantics(
  liveRegion: true,
  child: Text(
    _isRecording ? 'Registrazione video in corso' : 'Registrazione terminata',
    style: const TextStyle(fontSize: 0), // Visually hidden or integrated into UI
  ),
),
```

---

### 3. Low Severity

#### [LOW-01] Modal Header Heading Semantics
- **File**: `d:\Feditok\lib\screens\home\feed\camera_screen.dart`
- **Line(s)**: 190–193
- **WCAG Guideline**: WCAG 1.3.1 Info and Relationships (Level A)
- **Defect**: `'Dettagli Caricamento'` in the bottom sheet lacks `Semantics(header: true)`.
- **Code Fix**:
```dart
Semantics(
  header: true,
  child: const Text(
    'Dettagli Caricamento',
    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
  ),
),
```

---

## Automated Accessibility Testing Checklist

```dart
testWidgets('CameraScreen meets accessibility guidelines', (WidgetTester tester) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => FeedProvider())],
      child: const MaterialApp(home: CameraScreen()),
    ),
  );

  await expectLater(tester, meetsGuideline(textContrastGuideline));
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
});
```
