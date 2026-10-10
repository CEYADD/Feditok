import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_links/app_links.dart';

import '../../providers/auth_provider.dart';
import '../../services/activity_pub_oauth.dart';
import '../home/home_screen.dart';

class FediverseAuthScreen extends StatefulWidget {
  const FediverseAuthScreen({super.key});

  @override
  State<FediverseAuthScreen> createState() => _FediverseAuthScreenState();
}

class _FediverseAuthScreenState extends State<FediverseAuthScreen> {
  final _inputController = TextEditingController();

  bool _isConnecting = false;
  String? _statusMessage;
  String? _errorMessage;

  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  String? _currentInstance;
  String? _clientId;
  String? _clientSecret;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  /// Inizializza l'ascolto del callback Deep Link (`feditok://login-callback?code=...`)
  void _initDeepLinks() {
    _appLinks = AppLinks();
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        if (uri.scheme == 'feditok' && uri.host == 'login-callback') {
          final code = uri.queryParameters['code'];
          if (code != null && code.isNotEmpty) {
            _handleOAuthCallback(code);
          }
        }
      },
      onError: (err) {
        setState(() => _errorMessage = 'Errore deep link callback: $err');
      },
    );
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    _inputController.dispose();
    super.dispose();
  }

  void _startDynamicOAuthFlow() async {
    final input = _inputController.text.trim();

    if (input.isEmpty) {
      setState(
        () => _errorMessage = 'Inserisci la tua istanza (es. mastodon.social) o il tuo handle (es. @niko@mastodon.social)',
      );
      return;
    }

    final instanceDomain = DynamicActivityPubOAuth.extractDomain(input);
    if (instanceDomain.isEmpty || !instanceDomain.contains('.')) {
      setState(() => _errorMessage = 'Dominio istanza non valido.');
      return;
    }

    setState(() {
      _isConnecting = true;
      _errorMessage = null;
      _statusMessage =
          'Registrazione OAuth dinamica su https://$instanceDomain...';
    });

    try {
      _currentInstance = instanceDomain;

      // 1. Registra dinamicamente l'app sull'istanza dell'utente (`/api/v1/apps`)
      final creds = await DynamicActivityPubOAuth.registerOAuthApp(
        instanceDomain,
      );
      _clientId = creds['client_id'];
      _clientSecret = creds['client_secret'];

      setState(
        () => _statusMessage =
            'Apertura pagina di autorizzazione dell\'istanza...',
      );

      // 2. Genera l'URL OAuth e apre il browser dell'istanza
      final authUrl = DynamicActivityPubOAuth.getAuthorizationUrl(
        instanceDomain: instanceDomain,
        clientId: _clientId!,
      );

      final Uri uri = Uri.parse(authUrl);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('Impossibile aprire il browser per la registrazione.');
      }

      setState(
        () => _statusMessage =
            'In attesa dell\'autorizzazione su $instanceDomain...',
      );
    } catch (e) {
      setState(() {
        _isConnecting = false;
        _errorMessage = 'Errore OAuth Dinamico: ${e.toString()}';
      });
    }
  }

  /// 3. Gestisce il token exchange ed il sync del profilo con Supabase al ritorno dal Deep Link
  void _handleOAuthCallback(String code) async {
    if (_currentInstance == null ||
        _clientId == null ||
        _clientSecret == null) {
      setState(() {
        _isConnecting = false;
        _errorMessage = 'Sessione OAuth scaduta o non valida. Riprova.';
      });
      return;
    }

    setState(
      () => _statusMessage = 'Scambio token e autenticazione in corso...',
    );

    try {
      // Scambio codice -> Access Token
      final accessToken = await DynamicActivityPubOAuth.getAccessToken(
        instanceDomain: _currentInstance!,
        clientId: _clientId!,
        clientSecret: _clientSecret!,
        code: code,
      );

      setState(() => _statusMessage = 'Recupero dati profilo federato...');

      // Recupera il profilo dall'istanza ActivityPub
      final fediverseProfile =
          await DynamicActivityPubOAuth.fetchFediverseProfile(
            instanceDomain: _currentInstance!,
            accessToken: accessToken,
          );

      setState(
        () => _statusMessage = 'Sincronizzazione account su Supabase...',
      );

      // Crea o aggiorna il profilo su Supabase
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.loginOrRegisterFediverseProfile(fediverseProfile);

      if (!mounted) return;

      // Reindirizza direttamente alla HomeScreen dell'app
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } catch (e) {
      setState(() {
        _isConnecting = false;
        _errorMessage = 'Fallimento autenticazione federata: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Accedi con ActivityPub')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'ActivityPub',
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Inserisci il tuo handle o l\'indirizzo della tua istanza (es. mastodon.social, pixelfed.social, fosstodon.org).\nFeditok si connetterà dinamicamente in OAuth.',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.redAccent.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              TextField(
                controller: _inputController,
                enabled: !_isConnecting,
                decoration: InputDecoration(
                  labelText: 'Istanza o Handle (es. @niko@mastodon.social)',
                  hintText: 'mastodon.social',
                  prefixIcon: const Icon(Icons.hub_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isConnecting ? null : _startDynamicOAuthFlow,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: _isConnecting
                    ? Column(
                        children: [
                          const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          if (_statusMessage != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              _statusMessage!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      )
                    : const Text('Accedi con ActivityPub'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
