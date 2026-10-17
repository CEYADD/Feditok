# Accessibility (a11y) & WCAG Audit: EmailAuthScreen

**Target Scope**: `lib/screens/auth/email_auth_screen.dart` (`EmailAuthScreen`)  
**File Path**: `d:\Feditok\lib\screens\auth\email_auth_screen.dart`  
**WCAG Standard**: WCAG 2.1 / 2.2 Level AA  
**Platform Guidelines**: Android (48x48 dp), iOS (44x44 dp)

---

## Executive Summary

`EmailAuthScreen` manages user email verification, login, registration, password reset, and post-signup email confirmation. The audit revealed significant accessibility defects: an unlabeled checkbox for GitHub license acceptance, missing live region announcements for validation and network errors, an unlabelled edit icon button in the email field suffix, undersized tap targets on inline links, and reliance solely on color to convey error states.

---

## Findings by Severity

### 1. High Severity

#### [HIGH-01] Missing Live Region for Dynamic Error Messages
- **File**: `d:\Feditok\lib\screens\auth\email_auth_screen.dart`
- **Line(s)**: 188–202
- **WCAG Guideline**: WCAG 4.1.3 Status Messages (Level AA)
- **Defect**: When validation fails or server authentication errors occur, `_errorMessage` is set and displayed in a red `Container`. Because this container is not marked as a live region (`Semantics(liveRegion: true)`), TalkBack and VoiceOver users do not receive any notification of the error and may assume the button tap was unresponsive.
- **Code Fix**:
```dart
// Replace lines 188-202 in lib/screens/auth/email_auth_screen.dart:
if (_errorMessage != null) ...[
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
          const ExcludeSemantics(
            child: Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
          ),
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
  const SizedBox(height: 16),
],
```

#### [HIGH-02] Unlabeled Checkbox & Undersized Target on License Agreement Link
- **File**: `d:\Feditok\lib\screens\auth\email_auth_screen.dart`
- **Line(s)**: 277–303
- **WCAG Guideline**: WCAG 1.3.1 Info and Relationships (Level A), WCAG 4.1.2 Name, Role, Value (Level A), WCAG 2.5.5 / 2.5.8 Target Size (Level AA)
- **Defect**:
  1. The `Checkbox` widget has no `semanticLabel`. Screen readers announce "Checkbox, not checked" without conveying what agreement or terms the box binds to.
  2. The inline `InkWell` wrapping `"repo di GitHub"` has a tap target roughly the size of 14sp text (~14x100 dp), failing the 48x48 dp (Android) and 44x44 dp (iOS/WCAG) target size guidelines.
- **Code Fix**:
```dart
// Replace lines 277-303 with an accessible CheckboxListTile or Semantics-wrapped row:
CheckboxListTile(
  value: _acceptedLicense,
  contentPadding: EdgeInsets.zero,
  controlAffinity: ListTileControlAffinity.leading,
  onChanged: (val) {
    setState(() => _acceptedLicense = val ?? false);
  },
  title: Wrap(
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      const Text('Ho letto e accetto la licenza disponibile sulla '),
      Semantics(
        link: true,
        label: 'Apri repository GitHub in un browser esterno',
        child: InkWell(
          onTap: _launchGitHubRepo,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 2.0),
            child: Text(
              'repo di GitHub',
              style: TextStyle(
                color: Colors.blueAccent,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
      ),
    ],
  ),
),
```

---

### 2. Medium Severity

#### [MED-01] Missing Accessible Label on Suffix IconButton in Email TextField
- **File**: `d:\Feditok\lib\screens\auth\email_auth_screen.dart`
- **Line(s)**: 213–223
- **WCAG Guideline**: WCAG 1.1.1 Non-text Content (Level A), WCAG 4.1.2 Name, Role, Value (Level A)
- **Defect**: The email field has a suffix `IconButton(icon: Icon(Icons.edit))` when email is checked. It lacks a `tooltip` or `semanticLabel`. Assistive tools announce only "Pulsante", with no description of its function (modifying the entered email address).
- **Code Fix**:
```dart
suffixIcon: _emailChecked
    ? IconButton(
        icon: const Icon(Icons.edit),
        tooltip: 'Modifica indirizzo email',
        onPressed: () {
          setState(() {
            _emailChecked = false;
            _accountExists = false;
          });
        },
      )
    : null,
```

#### [MED-02] Use of Color Alone for Error Messaging
- **File**: `d:\Feditok\lib\screens\auth\email_auth_screen.dart`
- **Line(s)**: 189–200
- **WCAG Guideline**: WCAG 1.4.1 Use of Color (Level A)
- **Defect**: The error banner uses only red text on a faint red background without an accompanying warning/error icon or text prefix (e.g., "Errore:"). Colorblind users (e.g. protanopia/deuteranopia) may struggle to perceive the container as an error alert.
- **Code Fix**: Integrated into `[HIGH-01]` fix by adding `Icons.error_outline` alongside the message.

#### [MED-03] Missing Header Semantics on Confirmation View
- **File**: `d:\Feditok\lib\screens\auth\email_auth_screen.dart`
- **Line(s)**: 152–156
- **WCAG Guideline**: WCAG 1.3.1 Info and Relationships (Level A), WCAG 2.4.6 Headings and Labels (Level AA)
- **Defect**: The title `'Conferma il tuo indirizzo email'` on the confirmation screen is rendered as a plain `Text` widget without `Semantics(header: true)`.
- **Code Fix**:
```dart
Semantics(
  header: true,
  child: const Text(
    'Conferma il tuo indirizzo email',
    textAlign: TextAlign.center,
    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
  ),
),
```

---

### 3. Low Severity

#### [LOW-01] Decorative Text Field Prefix Icons
- **File**: `d:\Feditok\lib\screens\auth\email_auth_screen.dart`
- **Line(s)**: 211, 250, 271
- **WCAG Guideline**: WCAG 1.1.1 Non-text Content (Level A)
- **Defect**: Prefix icons (`Icons.email_outlined`, `Icons.lock_outline`, `Icons.lock_reset`) should be excluded from accessibility announcements as the input field already provides an accessible `labelText`.
- **Code Fix**:
```dart
prefixIcon: const ExcludeSemantics(child: Icon(Icons.email_outlined)),
```

---

## Automated Accessibility Testing Checklist

```dart
testWidgets('EmailAuthScreen meets accessibility guidelines', (WidgetTester tester) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
      child: const MaterialApp(home: EmailAuthScreen()),
    ),
  );

  await expectLater(tester, meetsGuideline(textContrastGuideline));
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
});
```
