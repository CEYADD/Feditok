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
  bool _isConnecting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _serverController.dispose();
    super.dispose();
  }

  void _startDynamicOAuth() async {
    final server = _serverController.text.trim();
    if (server.isEmpty) {
      setState(() => _errorMessage = 'Inserisci il nome del server (es. mastodon.social)');
      return;
    }

    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });

    // Simula il flusso OAuth dinamico dell'istanza ActivityPub
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Check se l'utente esiste già
    final isExistingUser = false; // Stub per primo accesso federato

    setState(() => _isConnecting = false);

    if (isExistingUser) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OnboardingScreen(
            isFediverse: true,
            fediverseHandle: '@user@$server',
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
        child: Padding(
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
                'Inserisci il dominio del tuo server Mastodon, Pleroma, Pixelfed o Misskey per iniziare l\'autenticazione OAuth dinamica.',
                style: TextStyle(color: Colors.grey[400], fontSize: 13),
              ),
              const SizedBox(height: 24),

              if (_errorMessage != null) ...[
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                ),
                const SizedBox(height: 12),
              ],

              TextField(
                controller: _serverController,
                decoration: InputDecoration(
                  labelText: 'Indirizzo Server (es. mastodon.social)',
                  prefixIcon: const Icon(Icons.dns_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),

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
                          Text('Connessione al server...'),
                        ],
                      )
                    : const Text('Avvia Dynamic OAuth'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
