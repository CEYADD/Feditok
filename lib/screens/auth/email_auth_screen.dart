import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../onboarding/onboarding_screen.dart';

class EmailAuthScreen extends StatefulWidget {
  const EmailAuthScreen({super.key});

  @override
  State<EmailAuthScreen> createState() => _EmailAuthScreenState();
}

class _EmailAuthScreenState extends State<EmailAuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isCheckingEmail = false;
  bool _emailChecked = false;
  bool _accountExists = false;
  bool _isOnboardingCompleted = false;
  bool _acceptedLicense = false;
  bool _showConfirmEmailNotice = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _verifyEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = 'Inserisci un indirizzo email valido.');
      return;
    }

    setState(() {
      _isCheckingEmail = true;
      _errorMessage = null;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final status = await authProvider.checkUserStatus(email);

    setState(() {
      _isCheckingEmail = false;
      _emailChecked = true;
      _accountExists = status['exists'] ?? false;
      _isOnboardingCompleted = status['isOnboardingCompleted'] ?? false;
    });
  }

  void _handleSubmit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    setState(() => _errorMessage = null);

    if (_accountExists) {
      // Login
      try {
        await authProvider.signInWithEmail(email, password);
        if (!mounted) return;

        if (!_isOnboardingCompleted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const OnboardingScreen()),
          );
        } else {
          Navigator.pop(context);
        }
      } catch (e) {
        setState(() => _errorMessage = 'Password errata o errore di accesso.');
      }
    } else {
      // Registrazione
      final confirmPassword = _confirmPasswordController.text;
      if (password != confirmPassword) {
        setState(() => _errorMessage = 'Le password non coincidono.');
        return;
      }
      if (!_acceptedLicense) {
        setState(() => _errorMessage = 'Devi accettare la licenza su GitHub per procedere.');
        return;
      }

      try {
        final user = await authProvider.signUpWithEmail(email, password);
        if (mounted) {
          if (user != null && user.emailConfirmedAt == null) {
            // MOSTRA SCHERMATA DI CONFERMA INDIRIZZO EMAIL
            setState(() => _showConfirmEmailNotice = true);
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const OnboardingScreen()),
            );
          }
        }
      } catch (e) {
        setState(() => _errorMessage = 'Errore durante la registrazione: ${e.toString()}');
      }
    }
  }

  void _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = 'Inserisci l\'email per il recupero password.');
      return;
    }

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.sendPasswordResetEmail(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email di reset password inviata! Controlla la tua casella di posta.')),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = 'Impossibile inviare l\'email di reset.');
    }
  }

  Future<void> _launchGitHubRepo() async {
    final Uri url = Uri.parse('https://github.com/PiedinoTimido/Feditok');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showConfirmEmailNotice) {
      return Scaffold(
        appBar: AppBar(title: const Text('Conferma Email')),
        body: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.mark_email_unread_outlined, size: 80, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 24),
              const Text(
                'Conferma il tuo indirizzo email',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'Dovrebbe esserti arrivata una mail per confermare l\'indirizzo email!\nUna volta confermato, torna qui ed effettua l\'accesso.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[400], fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Torna alla schermata iniziale'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accedi / Registrati'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Step 1: Input Email
              TextField(
                controller: _emailController,
                enabled: !_emailChecked,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  suffixIcon: _emailChecked
                      ? IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            setState(() {
                              _emailChecked = false;
                              _accountExists = false;
                            });
                          },
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 16),

              if (!_emailChecked) ...[
                ElevatedButton(
                  onPressed: _isCheckingEmail ? null : _verifyEmail,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isCheckingEmail
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Continua'),
                ),
              ] else ...[
                // Step 2: Login or Register Password fields
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 8),

                if (_accountExists) ...[
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _handleForgotPassword,
                      child: const Text('Hai dimenticato la password?'),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Conferma Password',
                      prefixIcon: const Icon(Icons.lock_reset),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Checkbox(
                        value: _acceptedLicense,
                        onChanged: (val) {
                          setState(() => _acceptedLicense = val ?? false);
                        },
                      ),
                      Expanded(
                        child: Wrap(
                          children: [
                            const Text('Ho letto e accetto la licenza disponibile sulla '),
                            InkWell(
                              onTap: _launchGitHubRepo,
                              child: const Text(
                                'repo di GitHub',
                                style: TextStyle(
                                  color: Colors.blueAccent,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),

                ElevatedButton(
                  onPressed: _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(_accountExists ? 'Accedi' : 'Conferma e Registrati'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
