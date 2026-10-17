# Accessibility (a11y) & WCAG Audit: OnboardingScreen

**Target Scope**: `lib/screens/onboarding/onboarding_screen.dart` (`OnboardingScreen`, `_RuleTile`)  
**File Path**: `d:\Feditok\lib\screens\onboarding\onboarding_screen.dart`  
**WCAG Standard**: WCAG 2.1 / 2.2 Level AA  
**Platform Guidelines**: Android (48x48 dp), iOS (44x44 dp)

---

## Executive Summary

The `OnboardingScreen` guides new users through a 4-step wizard: Full Name, Username check, Avatar selection, and Community Rules overview. Accessibility defects include unannounced linear progress steps, unmanaged keyboard focus during page changes across the `NeverScrollableScrollPhysics` `PageView`, absence of heading semantics on step headers, and fragmented screen reader announcements on community rule cards.

---

## Findings by Severity

### 1. High Severity

#### [HIGH-01] Keyboard Focus Trapping & Unannounced Step Progression in PageView
- **File**: `d:\Feditok\lib\screens\onboarding\onboarding_screen.dart`
- **Line(s)**: 72–80, 162–165
- **WCAG Guideline**: WCAG 2.4.3 Focus Order (Level A), WCAG 4.1.2 Name, Role, Value (Level A)
- **Defect**: The `PageView` is configured with `NeverScrollableScrollPhysics()`. When the user taps the "Avanti" button, `_pageController.nextPage()` animates to the next step, but keyboard focus stays locked onto the bottom "Avanti" button. Hardware keyboard and switch navigation users are not shifted into the active step container's inputs or titles, causing disorientation.
- **Code Fix**:
```dart
// Introduce FocusNodes for each step and request focus when stepping forward:
final FocusNode _stepFocusNode = FocusNode();

void _nextPage() async {
  // ... validations ...
  if (_currentStep < 3) {
    await _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() => _currentStep++);
    _stepFocusNode.requestFocus();
  } else {
    _finishOnboarding();
  }
}
```

#### [HIGH-02] Missing Live Region for Validation and Username Duplication Errors
- **File**: `d:\Feditok\lib\screens\onboarding\onboarding_screen.dart`
- **Line(s)**: 140–160
- **WCAG Guideline**: WCAG 4.1.3 Status Messages (Level AA)
- **Defect**: Error notices (e.g. "Il nome e cognome non possono essere vuoti", "Lo username è già stato preso") are rendered conditionally without `liveRegion: true`. Screen reader users do not receive automated verbal alerts when validation fails.
- **Code Fix**:
```dart
if (_errorMessage != null)
  Semantics(
    container: true,
    liveRegion: true,
    child: Container(
      margin: const EdgeInsets.all(16),
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
```

---

### 2. Medium Severity

#### [MED-01] Missing Semantics on Step Progress Indicator
- **File**: `d:\Feditok\lib\screens\onboarding\onboarding_screen.dart`
- **Line(s)**: 134–138
- **WCAG Guideline**: WCAG 1.1.1 Non-text Content (Level A), WCAG 4.1.2 Name, Role, Value (Level A)
- **Defect**: `LinearProgressIndicator` visually displays onboarding progress but lacks accessible labels, leaving screen readers unaware of the current wizard phase.
- **Code Fix**:
```dart
LinearProgressIndicator(
  value: (_currentStep + 1) / totalSteps,
  semanticsLabel: 'Avanzamento onboarding',
  semanticsValue: 'Passaggio ${_currentStep + 1} di $totalSteps',
  backgroundColor: Colors.grey[800],
  valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
),
```

#### [MED-02] Missing Heading Semantics on Step Titles
- **File**: `d:\Feditok\lib\screens\onboarding\onboarding_screen.dart`
- **Line(s)**: 323–326
- **WCAG Guideline**: WCAG 1.3.1 Info and Relationships (Level A), WCAG 2.4.6 Headings and Labels (Level AA)
- **Defect**: `_buildStepContainer` renders the step title as a raw `Text` widget without heading semantics.
- **Code Fix**:
```dart
Semantics(
  header: true,
  child: Text(
    title,
    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
  ),
),
```

#### [MED-03] Fragmented Screen Reader Announcements on Rule Cards
- **File**: `d:\Feditok\lib\screens\onboarding\onboarding_screen.dart`
- **Line(s)**: 340–364
- **WCAG Guideline**: WCAG 1.3.1 Info and Relationships (Level A)
- **Defect**: `_RuleTile` presents an icon, title, and subtitle inside a `ListTile`. Because the icon is decorative, screen readers announce the icon code or generic name before reading the title and subtitle as separate stops.
- **Code Fix**:
```dart
class _RuleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _RuleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white.withValues(alpha: 0.05),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: MergeSemantics(
        child: ListTile(
          leading: ExcludeSemantics(
            child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 28),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[400], fontSize: 13)),
        ),
      ),
    );
  }
}
```

---

### 3. Low Severity

#### [LOW-01] Missing Semantic Image Label on Avatar Preview
- **File**: `d:\Feditok\lib\screens\onboarding\onboarding_screen.dart`
- **Line(s)**: 229–240
- **WCAG Guideline**: WCAG 1.1.1 Non-text Content (Level A)
- **Defect**: The avatar `CircleAvatar` preview in Step 3 does not indicate whether a profile image has been chosen or if the placeholder icon is shown.
- **Code Fix**:
```dart
Semantics(
  image: true,
  label: _avatarUrl != null ? 'Foto profilo selezionata' : 'Nessuna foto profilo selezionata',
  child: CircleAvatar(
    radius: 54,
    backgroundColor: Colors.grey[800],
    backgroundImage: _avatarUrl != null ? ... : null,
    child: _avatarUrl == null ? const Icon(Icons.person, size: 54, color: Colors.white70) : null,
  ),
),
```

---

## Automated Accessibility Testing Checklist

```dart
testWidgets('OnboardingScreen meets accessibility guidelines', (WidgetTester tester) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
      child: const MaterialApp(home: OnboardingScreen()),
    ),
  );

  await expectLater(tester, meetsGuideline(textContrastGuideline));
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
});
```
