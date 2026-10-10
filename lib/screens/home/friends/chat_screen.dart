import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/friends_provider.dart';
import '../../../models/models.dart';

class ChatScreen extends StatefulWidget {
  final UserProfile friend;

  const ChatScreen({super.key, required this.friend});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _msgController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FriendsProvider>(context, listen: false).fetchMessages(widget.friend.id);
    });
  }

  @override
  void dispose() {
    _msgController.dispose();
    super.dispose();
  }

  void _send() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    _msgController.clear();
    final friendsProvider = Provider.of<FriendsProvider>(context, listen: false);
    await friendsProvider.sendMessage(widget.friend.id, text);
  }

  @override
  Widget build(BuildContext context) {
    final friendsProvider = Provider.of<FriendsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: widget.friend.avatarUrl != null ? NetworkImage(widget.friend.avatarUrl!) : null,
              child: widget.friend.avatarUrl == null ? Text(widget.friend.username[0].toUpperCase()) : null,
            ),
            const SizedBox(width: 10),
            Text(widget.friend.fullName ?? widget.friend.username),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            color: Colors.amber.withValues(alpha: 0.15),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.timer_outlined, size: 16, color: Colors.amber),
                SizedBox(width: 6),
                Text(
                  'I messaggi vengono eliminati automaticamente dopo 3 giorni',
                  style: TextStyle(color: Colors.amber, fontSize: 12),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: friendsProvider.messages.length,
              itemBuilder: (context, index) {
                final msg = friendsProvider.messages[index];
                final isMe = msg.senderId != widget.friend.id;

                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isMe ? Theme.of(context).colorScheme.primary : Colors.grey[800],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      msg.content,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    decoration: InputDecoration(
                      hintText: 'Scrivi un messaggio...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  color: Theme.of(context).colorScheme.primary,
                  onPressed: _send,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
