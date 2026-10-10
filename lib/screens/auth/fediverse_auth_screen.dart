import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../onboarding/onboarding_screen.dart';

class FediverseAuthScreen extends StatefulWidget {
  const FediverseAuthScreen({super.key});

  @override
  State<FediverseAuthScreen> createState() => _FediverseAuthScreenState();
}

class _FediverseAuthScreenState extends State<FediverseAuthScreen> {
  final _serverController = TextEditingController();
  final _usernameController = TextEditingController();
  bool _isConnecting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _serverController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _startDynamicOAuth() async {
    final server = _serverController.text.trim();
    final handleUser = _usernameController.text.trim();

    if (server.isEmpty) {
      setState(() => _errorMessage = 'Inserisci il nome del server (es. mastodon.social)');
      return;
    }

    if (handleUser.isEmpty) {
      setState(() => _errorMessage = 'Inserisci il tuo username sul server federato.');
      return;
    }

    final handle = '@${handleUser.replaceAll('@', '')}@$server';

    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Simula autenticazione OAuth dinamica e verifica esistenza profilo federato su Supabase
    await Future.delayed(const Duration(milliseconds: 1500));
    final existingUser = await authProvider.loginOrRegisterFediverse(handle);

    if (!mounted) return;

    setState(() => _isConnecting = false);

    if (existingUser != null) {
      // Utente esiste -> Vai alla Home (gestito via notifyListeners/AuthWrapper o pop)
      Navigator.popUntil(context, (route) => route.isFirst);
    } else {
      // Nuovo utente -> Vai all'onboarding
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OnboardingScreen(
            isFediverse: true,
            fediverseHandle: handle,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accedi con ActivityPub'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Fediverso / ActivityPub',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Inserisci il dominio del tuo server ActivityPub e il tuo username per connetterti in OAuth.',
                style: TextStyle(color: Colors.grey[400], fontSize: 13),
              ),
              const SizedBox(height: 24),

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

              TextField(
                controller: _serverController,
                decoration: InputDecoration(
                  labelText: 'Indirizzo Server (es. mastodon.social)',
                  prefixIcon: const Icon(Icons.dns_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username (es. @niko)',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isConnecting ? null : _startDynamicOAuth,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isConnecting
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Connessione Dynamic OAuth...'),
                        ],
                      )
                    : const Text('Autenticati con ActivityPub'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
