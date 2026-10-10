import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/friends_provider.dart';
import 'chat_screen.dart';

class FriendsTab extends StatefulWidget {
  const FriendsTab({super.key});

  @override
  State<FriendsTab> createState() => _FriendsTabState();
}

class _FriendsTabState extends State<FriendsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FriendsProvider>(context, listen: false).fetchFriends();
    });
  }

  void _openAddFriendDialog() {
    final searchController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Aggiungi un Amico'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Digita lo username esatto del tuo amico per inviargli una richiesta di amicizia.', style: TextStyle(fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Username (es. niko)',
                prefixIcon: const Icon(Icons.alternate_email),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () {
              final target = searchController.text.trim();
              if (target.isNotEmpty) {
                // Invia richiesta d'amicizia via Provider
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Richiesta d\'amicizia inviata a @$target!')),
                );
              }
            },
            child: const Text('Invia Richiesta'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final friendsProvider = Provider.of<FriendsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Amici'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1),
            tooltip: 'Aggiungi Amico',
            onPressed: _openAddFriendDialog,
          ),
        ],
      ),
      body: friendsProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : friendsProvider.friends.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey[600]),
                      const SizedBox(height: 16),
                      Text(
                        'Nessun amico presente.',
                        style: TextStyle(color: Colors.grey[400], fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _openAddFriendDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Cerca e invia richiesta'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: friendsProvider.friends.length,
                  itemBuilder: (context, index) {
                    final friend = friendsProvider.friends[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: friend.avatarUrl != null
                            ? NetworkImage(friend.avatarUrl!)
                            : null,
                        child: friend.avatarUrl == null
                            ? Text(friend.username[0].toUpperCase())
                            : null,
                      ),
                      title: Text(friend.fullName ?? friend.username),
                      subtitle: Text('@${friend.username}'),
                      trailing: const Icon(Icons.chat_bubble_outline),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(friend: friend),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}
