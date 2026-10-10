import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/friends_provider.dart';
import '../home/home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final bool isFediverse;
  final String? fediverseHandle;

  const OnboardingScreen({
    super.key,
    this.isFediverse = false,
    this.fediverseHandle,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  String? _avatarUrl;

  // Lista fittizia di persone con cui l'utente ha interagito nel Fediverso
  final List<Map<String, String>> _fediverseContacts = [
    {'name': 'Alex Rivera', 'handle': '@alex@mastodon.social'},
    {'name': 'Elena Rostova', 'handle': '@elena@pixelfed.social'},
    {'name': 'Marco Rossi', 'handle': '@marco@fedibox.it'},
  ];
  final Set<String> _sentRequests = {};

  @override
  void dispose() {
    _pageController.dispose();
    _fullNameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentStep < (widget.isFediverse ? 4 : 3)) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    } else {
      _finishOnboarding();
    }
  }

  void _finishOnboarding() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.completeOnboarding(
      fullName: _fullNameController.text.trim(),
      username: _usernameController.text.trim(),
      avatarUrl: _avatarUrl,
      isFediverse: widget.isFediverse,
      fediverseHandle: widget.fediverseHandle,
    );

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalSteps = widget.isFediverse ? 5 : 4;

    return Scaffold(
      appBar: AppBar(
        title: Text('Onboarding (${_currentStep + 1}/$totalSteps)'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(
              value: (_currentStep + 1) / totalSteps,
              backgroundColor: Colors.grey[800],
              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  // Step 1: Nome e Cognome
                  _buildStepContainer(
                    title: 'Come ti chiami?',
                    subtitle: 'Inserisci il tuo nome e cognome per farti riconoscere dagli amici.',
                    child: TextField(
                      controller: _fullNameController,
                      decoration: InputDecoration(
                        labelText: 'Nome e Cognome',
                        prefixIcon: const Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),

                  // Step 2: Username
                  _buildStepContainer(
                    title: 'Scegli un Username',
                    subtitle: 'Questo sarà il tuo identificativo unico su Feditok.',
                    child: TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: 'Username (es. @niko)',
                        prefixIcon: const Icon(Icons.alternate_email),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),

                  // Step 3: Immagine Profilo
                  _buildStepContainer(
                    title: 'Immagine Profilo',
                    subtitle: 'Personalizza la tua scheda prima di iniziare.',
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey[800],
                          backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                          child: _avatarUrl == null
                              ? const Icon(Icons.person, size: 50, color: Colors.white70)
                              : null,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _avatarUrl = 'https://picsum.photos/200';
                            });
                          },
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Carica Immagine Avatar'),
                        ),
                      ],
                    ),
                  ),

                  // Step 4 (Se ActivityPub): Lista interazioni
                  if (widget.isFediverse)
                    _buildStepContainer(
                      title: 'Amici dal Fediverso',
                      subtitle: 'Ecco le persone con cui hai interagito sul tuo server. Invia una richiesta!',
                      child: Expanded(
                        child: ListView.builder(
                          itemCount: _fediverseContacts.length,
                          itemBuilder: (context, index) {
                            final contact = _fediverseContacts[index];
                            final isSent = _sentRequests.contains(contact['handle']);
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                child: Text(contact['name']![0]),
                              ),
                              title: Text(contact['name']!),
                              subtitle: Text(contact['handle']!),
                              trailing: ElevatedButton(
                                onPressed: isSent
                                    ? null
                                    : () {
                                        setState(() {
                                          _sentRequests.add(contact['handle']!);
                                        });
                                      },
                                child: Text(isSent ? 'Inviata' : 'Aggiungi'),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                  // Step Finale: Regole Chiave dell'App
                  _buildStepContainer(
                    title: 'Regole della Community',
                    subtitle: 'Feditok è pensato per proteggere la tua privacy e combattere il doomscrolling.',
                    child: Expanded(
                      child: ListView(
                        children: const [
                          _RuleTile(
                            icon: Icons.timer_outlined,
                            title: 'Storie di 3 giorni',
                            subtitle: 'Vengono eliminate dal server automaticamente una volta viste da tutti gli amici.',
                          ),
                          _RuleTile(
                            icon: Icons.videocam_outlined,
                            title: 'Video max 3 minuti & 50MB',
                            subtitle: 'Video brevi e leggeri. I file pesanti vengono compressi automaticamente.',
                          ),
                          _RuleTile(
                            icon: Icons.chat_bubble_outline,
                            title: 'Chat temporanea',
                            subtitle: 'I messaggi tra amici si autocancellano dopo 3 giorni.',
                          ),
                          _RuleTile(
                            icon: Icons.sd_storage_outlined,
                            title: 'Backup locale automatico',
                            subtitle: 'I video rimossi dal server restano salvati in locale nel tuo telefono.',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    _currentStep == (totalSteps - 1) ? 'Inizia ad usare Feditok' : 'Avanti',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContainer({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}

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
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 28),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[400], fontSize: 13)),
      ),
    );
  }
}
