import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

class FriendsProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<UserProfile> _friends = [];
  List<ChatMessage> _messages = [];
  bool _isLoading = false;

  List<UserProfile> get friends => _friends;
  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;

  Future<void> fetchFriends() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final res = await _supabase
          .from('friends')
          .select('*, requester:profiles!requester_id(*), receiver:profiles!receiver_id(*)')
          .or('requester_id.eq.${user.id},receiver_id.eq.${user.id}')
          .eq('status', 'accepted');

      final List<UserProfile> tempFriends = [];
      for (final row in res as List<dynamic>) {
        if (row['requester_id'] == user.id) {
          tempFriends.add(UserProfile.fromJson(row['receiver']));
        } else {
          tempFriends.add(UserProfile.fromJson(row['requester']));
        }
      }
      _friends = tempFriends;
    } catch (e) {
      debugPrint('Error fetching friends: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendFriendRequest(String targetUserId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await _supabase.from('friends').insert({
      'requester_id': user.id,
      'receiver_id': targetUserId,
      'status': 'pending',
    });
  }

  Future<void> fetchMessages(String friendId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    // Messaggi filtrati per durare al massimo 3 giorni
    final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3)).toIso8601String();

    try {
      final res = await _supabase
          .from('messages')
          .select()
          .or('and(sender_id.eq.${user.id},receiver_id.eq.$friendId),and(sender_id.eq.$friendId,receiver_id.eq.${user.id})')
          .gte('created_at', threeDaysAgo)
          .order('created_at', ascending: true);

      _messages = (res as List).map((m) => ChatMessage.fromJson(m)).toList();
    } catch (e) {
      debugPrint('Error fetching messages: $e');
    }
    notifyListeners();
  }

  Future<void> sendMessage(String friendId, String text) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final msgData = {
      'sender_id': user.id,
      'receiver_id': friendId,
      'content': text,
      'created_at': DateTime.now().toIso8601String(),
    };

    final res = await _supabase.from('messages').insert(msgData).select().single();
    _messages.add(ChatMessage.fromJson(res));
    notifyListeners();
  }
}
