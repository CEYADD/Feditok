import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/feed_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final feedProvider = Provider.of<FeedProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Impostazioni'),
      ),
      body: ListView(
        children: [
          // 1. Sezione Accesso
          _buildSectionHeader(context, 'Accesso'),
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text('Modifica Email'),
            onTap: () {
              _showSimpleDialog(context, 'Modifica Email', 'Inserisci la nuova email da associare al tuo account.');
            },
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Modifica Password'),
            onTap: () {
              _showSimpleDialog(context, 'Modifica Password', 'Inserisci la tua attuale password e quella nuova.');
            },
          ),

          const Divider(),

          // 2. Sezione Privacy
          _buildSectionHeader(context, 'Privacy'),
          ListTile(
            leading: const Icon(Icons.cloud_outlined),
            title: const Text('Visualizza Video Online'),
            subtitle: const Text('Gestisci o elimina i tuoi video pubblicati sul server'),
            onTap: () {
              _showOnlineVideosModal(context);
            },
          ),

          const Divider(),

          // 3. Sezione Memoria
          _buildSectionHeader(context, 'Memoria'),
          ListTile(
            leading: const Icon(Icons.folder_special_outlined),
            title: const Text('Gestione Video Salvati in Locale'),
            subtitle: Text('${feedProvider.savedLocalVideoPaths.length} video salvati nel dispositivo'),
            onTap: () {
              _showLocalMemoryModal(context, feedProvider);
            },
          ),

          const Divider(),

          // 4. Sezione Danger Zone
          _buildSectionHeader(context, 'Danger Zone', isDanger: true),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.orangeAccent),
            title: const Text('Logout', style: TextStyle(color: Colors.orangeAccent)),
            onTap: () async {
              await authProvider.signOut();
              if (context.mounted) Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.download_outlined, color: Colors.amber),
            title: const Text('Richiedi Copia Dati'),
            subtitle: const Text('Invia un\'email con tutti i dati del tuo profilo'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Richiesta inviata! Riceverai una mail a breve.')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
            title: const Text('Cancellazione Definitiva Profilo', style: TextStyle(color: Colors.redAccent)),
            onTap: () {
              _showDeleteConfirmation(context, authProvider);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, {bool isDanger = false}) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: isDanger ? Colors.redAccent : Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  void _showSimpleDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Chiudi')),
        ],
      ),
    );
  }

  void _showOnlineVideosModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        padding: const EdgeInsets.all(16),
        height: 300,
        child: const Column(
          children: [
            Text('I Tuoi Video sul Server', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Divider(),
            Expanded(
              child: Center(
                child: Text('Tutti i video attivi sul server verranno eliminati dopo 3 giorni.'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLocalMemoryModal(BuildContext context, FeedProvider feedProvider) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        padding: const EdgeInsets.all(16),
        height: 350,
        child: Column(
          children: [
            const Text('Memoria Locale', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Divider(),
            Expanded(
              child: feedProvider.savedLocalVideoPaths.isEmpty
                  ? const Center(child: Text('Nessun video salvato in locale.'))
                  : ListView.builder(
                      itemCount: feedProvider.savedLocalVideoPaths.length,
                      itemBuilder: (context, index) {
                        final path = feedProvider.savedLocalVideoPaths[index];
                        return ListTile(
                          title: Text('Video Local #${index + 1}'),
                          subtitle: Text(path, maxLines: 1),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () => feedProvider.deleteLocalVideo(path),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Conferma Cancellazione'),
        content: const Text('Sei sicuro di voler eliminare definitivamente il tuo profilo? Questa azione non può essere annullata.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              await authProvider.deleteAccount();
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
              }
            },
            child: const Text('Elimina Definitivemente'),
          ),
        ],
      ),
    );
  }
}
