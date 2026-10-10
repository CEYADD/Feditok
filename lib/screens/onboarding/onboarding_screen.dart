import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
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
  
  bool _isCheckingUsername = false;
  String? _errorMessage;

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _pageController.dispose();
    _fullNameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _nextPage() async {
    setState(() => _errorMessage = null);

    // Step 1: Nome e cognome non vuoti
    if (_currentStep == 0) {
      if (_fullNameController.text.trim().isEmpty) {
        setState(() => _errorMessage = 'Il nome e cognome non possono essere vuoti.');
        return;
      }
    }

    // Step 2: Username non vuoto e controllo duplicati su Supabase
    if (_currentStep == 1) {
      final username = _usernameController.text.trim();
      if (username.isEmpty) {
        setState(() => _errorMessage = 'Lo username non può essere vuoto.');
        return;
      }

      setState(() => _isCheckingUsername = true);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final isTaken = await authProvider.checkUsernameExists(username);
      setState(() => _isCheckingUsername = false);

      if (isTaken) {
        setState(() => _errorMessage = 'Lo username "$username" è già stato preso. Scegline un altro.');
        return;
      }
    }

    if (_currentStep < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    } else {
      _finishOnboarding();
    }
  }

  Future<void> _pickAvatarImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _avatarUrl = image.path;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Immagine di profilo selezionata!')),
          );
        }
      }
    } catch (e) {
      setState(() {
        _avatarUrl = 'https://picsum.photos/200';
      });
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
    const totalSteps = 4;

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
            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
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
                        labelText: 'Nome e Cognome *',
                        prefixIcon: const Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),

                  // Step 2: Username
                  _buildStepContainer(
                    title: 'Scegli un Username',
                    subtitle: 'Questo sarà il tuo identificativo unico su Feditok.',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            labelText: 'Username (es. @niko) *',
                            prefixIcon: const Icon(Icons.alternate_email),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        if (_isCheckingUsername) ...[
                          const SizedBox(height: 12),
                          const Row(
                            children: [
                              SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                              SizedBox(width: 10),
                              Text('Verifica disponibilità username su server...', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Step 3: Immagine Profilo (Centrata!)
                  Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'Immagine Profilo',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Personalizza la tua foto prima di iniziare.',
                            style: TextStyle(color: Colors.grey[400], fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 28),
                          CircleAvatar(
                            radius: 54,
                            backgroundColor: Colors.grey[800],
                            backgroundImage: _avatarUrl != null
                                ? (_avatarUrl!.startsWith('http')
                                    ? NetworkImage(_avatarUrl!) as ImageProvider
                                    : AssetImage(_avatarUrl!)) // Fallback per il file picker
                                : null,
                            child: _avatarUrl == null
                                ? const Icon(Icons.person, size: 54, color: Colors.white70)
                                : null,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _pickAvatarImage,
                            icon: const Icon(Icons.photo_camera_outlined),
                            label: const Text('Carica Immagine Avatar'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Step 4 (Ex finale): Regole Chiave dell'App
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
                  onPressed: _isCheckingUsername ? null : _nextPage,
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
