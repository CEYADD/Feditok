import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/friends_provider.dart';
import '../../../models/models.dart';
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

  @override
  Widget build(BuildContext context) {
    final friendsProvider = Provider.of<FriendsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Amici'),
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
                        'Nessun amico trovato.',
                        style: TextStyle(color: Colors.grey[400], fontSize: 16),
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
