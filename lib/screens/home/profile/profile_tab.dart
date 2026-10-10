import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/feed_provider.dart';
import 'settings_screen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  Future<void> _openBuyMeACoffee() async {
    final Uri url = Uri.parse('https://buymeacoffee.com');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch BuyMeACoffee');
    }
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
                      ? Image.network(user!.bannerUrl!, fit: BoxFit.cover)
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
                              ? NetworkImage(user!.avatarUrl!)
                              : null,
                          child: user?.avatarUrl == null
                              ? const Icon(Icons.person, size: 42)
                              : null,
                        ),
                      ),
                      // Rank Badge in basso a destra dell'avatar
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

            // Rank Coming Soon Card
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              color: Colors.amber.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Colors.amber.withValues(alpha: 0.4)),
              ),
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.workspace_premium, color: Colors.amber),
                        SizedBox(width: 8),
                        Text(
                          'Sistema di Rank (Coming Soon)',
                          style: TextStyle(
                            color: Colors.amber,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Ottieni il rank "Supporter" e sblocca badge esclusivi tramite le donazioni al progetto!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Pulsante Donazione BuyMeACoffee
            ElevatedButton.icon(
              onPressed: _openBuyMeACoffee,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFDD00),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              icon: const Icon(Icons.coffee),
              label: const Text(
                'Supporta il progetto su BuyMeACoffee',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 24),

            // Sezione Video Attivi / Salvati
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'I Tuoi Video Active & Salvati Localmente',
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
