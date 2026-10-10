import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class FeedProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<VideoItem> _feedVideos = [];
  List<String> _savedLocalVideoPaths = [];
  bool _isLoading = false;

  List<VideoItem> get feedVideos => _feedVideos;
  List<String> get savedLocalVideoPaths => _savedLocalVideoPaths;
  bool get isLoading => _isLoading;

  FeedProvider() {
    loadSavedLocalVideos();
  }

  // Caricamento del feed in stretta cronologia ordinato dal più recente
  Future<void> fetchChronologicalFeed() async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _supabase
          .from('videos')
          .select('*, profiles!user_id(*)')
          .order('created_at', ascending: false);

      final List<VideoItem> items = [];
      for (final item in res as List<dynamic>) {
        final author = UserProfile.fromJson(item['profiles']);
        items.add(VideoItem.fromJson(item, author: author));
      }
      _feedVideos = items;
    } catch (e) {
      debugPrint('Error fetching feed: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleLike(String videoId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final existing = await _supabase
          .from('video_likes')
          .select()
          .eq('video_id', videoId)
          .eq('user_id', user.id)
          .maybeSingle();

      if (existing != null) {
        await _supabase.from('video_likes').delete().eq('id', existing['id']);
      } else {
        await _supabase.from('video_likes').insert({
          'video_id': videoId,
          'user_id': user.id,
        });
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling like: $e');
    }
  }

  // Salvataggio video locale (per backup/repost)
  Future<void> saveVideoLocally(String videoUrl, String videoId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> saved = prefs.getStringList('saved_videos') ?? [];
      
      if (!saved.contains(videoUrl)) {
        saved.add(videoUrl);
        await prefs.setStringList('saved_videos', saved);
        _savedLocalVideoPaths = saved;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error saving video locally: $e');
    }
  }

  Future<void> loadSavedLocalVideos() async {
    final prefs = await SharedPreferences.getInstance();
    _savedLocalVideoPaths = prefs.getStringList('saved_videos') ?? [];
    notifyListeners();
  }

  Future<void> deleteLocalVideo(String path) async {
    final prefs = await SharedPreferences.getInstance();
    _savedLocalVideoPaths.remove(path);
    await prefs.setStringList('saved_videos', _savedLocalVideoPaths);
    notifyListeners();
  }
}
