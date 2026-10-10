import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/feed_provider.dart';
import '../../../models/models.dart';
import 'settings_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  // Notifiche stub per demo
  final List<AppNotification> _notifications = [
    AppNotification(
      id: '1',
      type: 'friend_request',
      title: 'Richiesta d\'amicizia',
      message: '@elena ti ha inviato una richiesta di amicizia!',
      createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
      isRead: false,
    ),
    AppNotification(
      id: '2',
      type: 'like',
      title: 'Nuovo Mi piace',
      message: '@marco ha messo mi piace al tuo video!',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      isRead: false,
    ),
  ];

  bool get _hasUnreadNotifications => _notifications.any((n) => !n.isRead);

  void _openEditProfileDialog(BuildContext context, AuthProvider authProvider) {
    final user = authProvider.currentProfile;
    final usernameController = TextEditingController(text: user?.username);
    final fullNameController = TextEditingController(text: user?.fullName);
    final bioController = TextEditingController(text: user?.bio);

    String? avatarPath = user?.avatarUrl;
    String? bannerPath = user?.bannerUrl;

    final picker = ImagePicker();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Modifica Profilo'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Banner Selector
                GestureDetector(
                  onTap: () async {
                    final img = await picker.pickImage(source: ImageSource.gallery);
                    if (img != null) {
                      setDialogState(() => bannerPath = img.path);
                    }
                  },
                  child: Container(
                    height: 80,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(8),
                      image: bannerPath != null
                          ? DecorationImage(
                              image: bannerPath!.startsWith('http')
                                  ? NetworkImage(bannerPath!)
                                  : AssetImage(bannerPath!) as ImageProvider,
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, color: Colors.white70),
                          SizedBox(width: 6),
                          Text('Cambia Banner', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Avatar Selector
                GestureDetector(
                  onTap: () async {
                    final img = await picker.pickImage(source: ImageSource.gallery);
                    if (img != null) {
                      setDialogState(() => avatarPath = img.path);
                    }
                  },
                  child: CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.grey[700],
                    backgroundImage: avatarPath != null
                        ? (avatarPath!.startsWith('http')
                            ? NetworkImage(avatarPath!)
                            : AssetImage(avatarPath!) as ImageProvider)
                        : null,
                    child: const Icon(Icons.photo_camera, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    prefixIcon: const Icon(Icons.alternate_email),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: fullNameController,
                  decoration: InputDecoration(
                    labelText: 'Nome e Cognome',
                    prefixIcon: const Icon(Icons.badge),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bioController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Biografia',
                    prefixIcon: const Icon(Icons.notes),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              onPressed: () async {
                await authProvider.updateProfile(
                  username: usernameController.text.trim(),
                  fullName: fullNameController.text.trim(),
                  bio: bioController.text.trim(),
                  avatarUrl: avatarPath,
                  bannerUrl: bannerPath,
                );
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Salva'),
            ),
          ],
        ),
      ),
    );
  }

  void _openRankInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.workspace_premium, color: Colors.amber),
            SizedBox(width: 8),
            Text('Sistema di Rank & Badges'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Su Feditok premiamo la sostenibilità dell\'open source!',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text('• User: Il rank base per tutti i membri della community.'),
              const SizedBox(height: 6),
              const Text('• Supporter: Ottenuto effettuando una donazione libera al progetto Feditok.'),
              const SizedBox(height: 6),
              const Text('• Tier Pro / Contributor: Riservato ai contributori di codice su GitHub.'),
              const SizedBox(height: 20),

              // Pulsante BuyMeACoffee NON CLICCABILE (come richiesto)
              ElevatedButton.icon(
                onPressed: null, // DISABILITATO / NON CLICCABILE
                icon: const Icon(Icons.coffee),
                label: const Text('Supporta su BuyMeACoffee (Non attivo)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[700],
                  disabledBackgroundColor: Colors.grey[800],
                  disabledForegroundColor: Colors.white38,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Chiudi')),
        ],
      ),
    );
  }

  void _openNotificationsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Notifiche'),
        content: SizedBox(
          width: double.maxFinite,
          height: 280,
          child: _notifications.isEmpty
              ? const Center(child: Text('Nessuna notifica.'))
              : ListView.builder(
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notif = _notifications[index];
                    return ListTile(
                      leading: Icon(
                        notif.type == 'friend_request'
                            ? Icons.person_add
                            : Icons.favorite,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: Text(notif.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text(notif.message, style: const TextStyle(fontSize: 12)),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                for (var n in _notifications) {
                  // Segna lette
                }
              });
              Navigator.pop(context);
            },
            child: const Text('Chiudi'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final feedProvider = Provider.of<FeedProvider>(context);
    final user = authProvider.currentProfile;

    return Scaffold(
      appBar: AppBar(
        title: Text(user?.username ?? 'Profilo'),
        actions: [
          // 8. Tasto Matita (Modifica Profilo)
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Modifica Profilo',
            onPressed: () => _openEditProfileDialog(context, authProvider),
          ),

          // 8. Tasto Caffè (Spiega Rank & BuyMeACoffee disabilitato)
          IconButton(
            icon: const Icon(Icons.local_cafe_outlined, color: Colors.amber),
            tooltip: 'Rank & Supporto',
            onPressed: () => _openRankInfoDialog(context),
          ),

          // 8. Tasto Campanella Notifiche (con ! se non lette)
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none),
                tooltip: 'Notifiche',
                onPressed: () => _openNotificationsDialog(context),
              ),
              if (_hasUnreadNotifications)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: const Text(
                      '!',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),

          // Impostazioni
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Banner & Avatar
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  height: 140,
                  width: double.infinity,
                  color: Colors.grey[800],
                  child: user?.bannerUrl != null
                      ? (user!.bannerUrl!.startsWith('http')
                          ? Image.network(user.bannerUrl!, fit: BoxFit.cover)
                          : Image.asset(user.bannerUrl!, fit: BoxFit.cover))
                      : null,
                ),
                Positioned(
                  bottom: -40,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 46,
                        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                        child: CircleAvatar(
                          radius: 42,
                          backgroundImage: user?.avatarUrl != null
                              ? (user!.avatarUrl!.startsWith('http')
                                  ? NetworkImage(user.avatarUrl!)
                                  : AssetImage(user.avatarUrl!) as ImageProvider)
                              : null,
                          child: user?.avatarUrl == null
                              ? const Icon(Icons.person, size: 42)
                              : null,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, size: 12, color: Colors.black),
                              const SizedBox(width: 2),
                              Text(
                                user?.rank ?? 'Supporter',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 50),

            // User Info
            Text(
              user?.fullName ?? user?.username ?? 'Utente Feditok',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              '@${user?.username ?? "username"}',
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                user?.bio ?? 'Nessuna biografia inserita.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[300], fontSize: 13),
              ),
            ),
            const SizedBox(height: 24),

            // Sezione Video Attivi / Salvati
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'I Tuoi Video Salvati Localmente',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 12),

            feedProvider.savedLocalVideoPaths.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      'Nessun video salvato in locale.',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: feedProvider.savedLocalVideoPaths.length,
                    itemBuilder: (context, index) {
                      final item = feedProvider.savedLocalVideoPaths[index];
                      return ListTile(
                        leading: const Icon(Icons.video_file),
                        title: Text('Video #${index + 1}'),
                        subtitle: Text(item, maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () {
                            feedProvider.deleteLocalVideo(item);
                          },
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
