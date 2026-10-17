# Accessibility (a11y) & WCAG Audit: WelcomeScreen

**Target Scope**: `lib/screens/auth/welcome_screen.dart` (`WelcomeScreen`)  
**File Path**: `d:\Feditok\lib\screens\auth\welcome_screen.dart`  
**WCAG Standard**: WCAG 2.1 / 2.2 Level AA  
**Platform Guidelines**: Android (48x48 dp), iOS (44x44 dp)

---

## Executive Summary

The `WelcomeScreen` is the entry point for unauthenticated users. It features the Feditok logo, introductory tagline, and two primary authentication options ("Accedi con Email" and "Accedi con ActivityPub"). Overall structure is clean, but several accessibility defects were identified, including missing heading semantics, lack of overflow protection under system text scaling, decorative icon leakage to screen readers, and absence of automated accessibility testing.

---

## Findings by Severity

### 1. High Severity

#### [HIGH-01] Text Scaling & RenderFlex Overflow Risk on High Text Scale Factors
- **File**: `d:\Feditok\lib\screens\auth\welcome_screen.dart`
- **Line(s)**: 14–18, 56
- **WCAG Guideline**: WCAG 1.4.4 Resize Text (Level AA), WCAG 1.4.10 Reflow (Level AA)
- **Defect**: The screen layout uses a rigid `Column` containing multiple `Spacer()` widgets without being wrapped in a `SingleChildScrollView`. When users enable large system font scaling (e.g. 1.5x – 2.0x text scale factor) or view the app on smaller screens / landscape orientation, the fixed vertical spacing and non-scrollable column will throw a `RenderFlex overflowed by N pixels` visual error, clipping the action buttons and preventing user login.
- **Code Fix**:
```dart
// Replace lines 12-18 in lib/screens/auth/welcome_screen.dart:
// Before:
// child: Padding(
//   padding: const EdgeInsets.symmetric(horizontal: 28.0),
//   child: Column(
//     mainAxisAlignment: MainAxisAlignment.center,
//     crossAxisAlignment: CrossAxisAlignment.stretch,
//     children: [
//       const Spacer(),

// After:
child: SafeArea(
  child: LayoutBuilder(
    builder: (context, constraints) {
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
          child: IntrinsicHeight(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                // ... content remains responsive
```

---

### 2. Medium Severity

#### [MED-01] Missing Header Semantics on Primary Screen Heading
- **File**: `d:\Feditok\lib\screens\auth\welcome_screen.dart`
- **Line(s)**: 35–42
- **WCAG Guideline**: WCAG 1.3.1 Info and Relationships (Level A), WCAG 2.4.6 Headings and Labels (Level AA)
- **Defect**: The app title `Feditok` is rendered as a raw `Text` widget without heading semantics. Assistive technologies (TalkBack / VoiceOver) cannot identify this element as the page title when users navigate via the headings rotor.
- **Code Fix**:
```dart
// Replace lines 35-42 in lib/screens/auth/welcome_screen.dart:
Semantics(
  header: true,
  child: const Text(
    'Feditok',
    style: TextStyle(
      fontSize: 36,
      fontWeight: FontWeight.bold,
      letterSpacing: 1.2,
    ),
  ),
),
```

#### [MED-02] Decorative Icons Announced Redundantly by Screen Readers
- **File**: `d:\Feditok\lib\screens\auth\welcome_screen.dart`
- **Line(s)**: 28–32, 78, 108
- **WCAG Guideline**: WCAG 1.1.1 Non-text Content (Level A)
- **Defect**: 
  1. The bolt icon `Icons.bolt_rounded` inside the decorative circle is purely decorative branding.
  2. The button icons `Icons.email_outlined` and `Icons.hub_outlined` accompany explicit textual labels ("Accedi con Email" and "Accedi con ActivityPub"). Without `ExcludeSemantics`, TalkBack / VoiceOver reads "email icon, Accedi con Email, button", cluttering screen reader navigation with redundant cues.
- **Code Fix**:
```dart
// 1. Exclude the decorative hero bolt icon (lines 28-32):
ExcludeSemantics(
  child: Icon(
    Icons.bolt_rounded,
    size: 64,
    color: Theme.of(context).colorScheme.primary,
  ),
),

// 2. Exclude decorative button icons (lines 78 and 108):
const Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    ExcludeSemantics(child: Icon(Icons.email_outlined)),
    SizedBox(width: 12),
    Text(
      'Accedi con Email',
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
  ],
),
```

---

### 3. Low Severity

#### [LOW-01] Button Semantics Grouping with MergeSemantics
- **File**: `d:\Feditok\lib\screens\auth\welcome_screen.dart`
- **Line(s)**: 59–86, 90–116
- **WCAG Guideline**: WCAG 4.1.2 Name, Role, Value (Level A)
- **Defect**: While `ElevatedButton` and `OutlinedButton` natively expose the button trait, wrapping the internal `Row` in `MergeSemantics` or ensuring single label announcement guarantees that the button's icon and label are never segmented into distinct virtual elements on legacy screen reader engines.
- **Code Fix**:
```dart
ElevatedButton(
  onPressed: () { ... },
  // ... style ...
  child: const MergeSemantics(
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ExcludeSemantics(child: Icon(Icons.email_outlined)),
        SizedBox(width: 12),
        Text('Accedi con Email', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ],
    ),
  ),
)
```

---

## Automated Accessibility Testing Checklist

Add widget tests for `WelcomeScreen` asserting Flutter's accessibility guidelines:
```dart
testWidgets('WelcomeScreen meets accessibility guidelines', (WidgetTester tester) async {
  await tester.pumpWidget(const MaterialApp(home: WelcomeScreen()));

  // WCAG Guidelines automated checks
  await expectLater(tester, meetsGuideline(textContrastGuideline));
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
});
```
