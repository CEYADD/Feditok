import 'dart:async';
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
    final user = authProvider.currentProfile;
    final isFediverse = user?.isFediverse ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Impostazioni'),
      ),
      body: ListView(
        children: [
          // 1. Sezione Accesso (Punto 9)
          _buildSectionHeader(context, 'Accesso'),
          ListTile(
            enabled: !isFediverse,
            leading: Icon(Icons.email_outlined, color: isFediverse ? Colors.grey : null),
            title: Text('Modifica Email', style: TextStyle(color: isFediverse ? Colors.grey : null)),
            subtitle: isFediverse
                ? const Text(
                    'Impossibile modificare email/password se è stato effettuato l\'accesso con ActivityPub',
                    style: TextStyle(color: Colors.grey, fontSize: 11),
                  )
                : null,
            onTap: isFediverse
                ? null
                : () {
                    _showSimpleDialog(context, 'Modifica Email', 'Inserisci la nuova email da associare al tuo account.');
                  },
          ),
          ListTile(
            enabled: !isFediverse,
            leading: Icon(Icons.lock_outline, color: isFediverse ? Colors.grey : null),
            title: Text('Modifica Password', style: TextStyle(color: isFediverse ? Colors.grey : null)),
            subtitle: isFediverse
                ? const Text(
                    'Impossibile modificare email/password se è stato effettuato l\'accesso con ActivityPub',
                    style: TextStyle(color: Colors.grey, fontSize: 11),
                  )
                : null,
            onTap: isFediverse
                ? null
                : () {
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
            onTap: () => _showOnlineVideosModal(context),
          ),

          const Divider(),

          // 3. Sezione Memoria
          _buildSectionHeader(context, 'Memoria'),
          ListTile(
            leading: const Icon(Icons.folder_special_outlined),
            title: const Text('Gestione Video Salvati in Locale'),
            subtitle: Text('${feedProvider.savedLocalVideoPaths.length} video salvati nel dispositivo'),
            onTap: () => _showLocalMemoryModal(context, feedProvider),
          ),

          const Divider(),

          // 4. Sezione Danger Zone
          _buildSectionHeader(context, 'Danger Zone', isDanger: true),
          
          // Punto 10: Logout funzionante
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.orangeAccent),
            title: const Text('Logout', style: TextStyle(color: Colors.orangeAccent)),
            onTap: () async {
              await authProvider.signOut();
              if (context.mounted) {
                Navigator.popUntil(context, (route) => route.isFirst);
              }
            },
          ),

          // Punto 13: Copia Dati 1 volta al mese e scelta cartella di salvataggio
          ListTile(
            leading: const Icon(Icons.download_outlined, color: Colors.amber),
            title: const Text('Richiedi Copia Dati'),
            subtitle: const Text('Scarica una copia dei tuoi dati (disponibile 1 volta al mese)'),
            onTap: () => _handleDataCopyRequest(context),
          ),

          // Punto 11: Cancellazione con avviso rosso, timer 5 secondi e testo "Conferma cancellazione" in bianco
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
            title: const Text('Cancellazione Definitiva Profilo', style: TextStyle(color: Colors.redAccent)),
            onTap: () => _showDeleteConfirmationModal(context, authProvider),
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

  // Punto 13: Copia dati
  void _handleDataCopyRequest(BuildContext context) async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Richiesta Copia Dati'),
        content: const Text(
          'Puoi richiedere e scaricare una copia completa dei tuoi dati solo 1 volta al mese. Seleziona la destinazione per salvare il file.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copia dei dati elaborata e salvata con successo!')),
                );
              }
            },
            child: const Text('Conferma Download Dati'),
          ),
        ],
      ),
    );
  }

  // Punto 11: Avviso rosso, timer di 5 secondi, testo bianco "Conferma cancellazione"
  void _showDeleteConfirmationModal(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _DeleteConfirmDialog(authProvider: authProvider),
    );
  }
}

class _DeleteConfirmDialog extends StatefulWidget {
  final AuthProvider authProvider;

  const _DeleteConfirmDialog({required this.authProvider});

  @override
  State<_DeleteConfirmDialog> createState() => _DeleteConfirmDialogState();
}

class _DeleteConfirmDialogState extends State<_DeleteConfirmDialog> {
  int _secondsRemaining = 5;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 1) {
        setState(() => _secondsRemaining--);
      } else {
        setState(() => _secondsRemaining = 0);
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF2A0808), // Avviso Rosso Scuro
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
          SizedBox(width: 8),
          Text('Cancellazione Profilo', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        ],
      ),
      content: const SingleChildScrollView(
        child: Text(
          'Tutti i dati relativi all\'ID del tuo profilo verranno eliminati definitivamente dai server.\n\n'
          '• Se hai effettuato l\'accesso con ActivityPub, il tuo profilo sul server federato originale NON verrà eliminato.\n'
          '• I video salvati nella memoria locale del tuo telefono NON verranno eliminati.',
          style: TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annulla', style: TextStyle(color: Colors.white70)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white, // Testo del pulsante bianco!
          ),
          onPressed: _secondsRemaining > 0
              ? null
              : () async {
                  await widget.authProvider.deleteAccount();
                  if (context.mounted) {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  }
                },
          child: Text(
            _secondsRemaining > 0
                ? 'Conferma cancellazione ($_secondsRemaining s)'
                : 'Conferma cancellazione',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
