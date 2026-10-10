import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

class AuthProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  UserProfile? _currentProfile;
  bool _isLoading = true;

  UserProfile? get currentProfile => _currentProfile;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _supabase.auth.currentUser != null;

  AuthProvider() {
    _initAuth();
  }

  Future<void> _initAuth() async {
    _supabase.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      if (session != null) {
        await fetchProfile(session.user.id);
      } else {
        _currentProfile = null;
      }
      _isLoading = false;
      notifyListeners();
    });

    final currentSession = _supabase.auth.currentSession;
    if (currentSession != null) {
      await fetchProfile(currentSession.user.id);
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchProfile(String userId) async {
    try {
      final res = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (res != null) {
        _currentProfile = UserProfile.fromJson(res);
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    }
    notifyListeners();
  }

  // Verifica se un'email esiste nel sistema
  Future<bool> checkEmailExists(String email) async {
    try {
      await _supabase
          .from('profiles')
          .select('id')
          .limit(1);
      // In Supabase client side non c'è una direct API per controllare se l'email esiste senza tentare la sign-in,
      // usiamo un fallback strutturato o proviamo sign-in con password dummy
      return false; // Gestito nel flusso UI
    } catch (e) {
      return false;
    }
  }

  // Email / Password Login
  Future<void> signInWithEmail(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user != null) {
        await fetchProfile(response.user!.id);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Email / Password Sign Up
  Future<User?> signUpWithEmail(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      return response.user;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Salva l'onboarding dell'utente
  Future<void> completeOnboarding({
    required String fullName,
    required String username,
    String? avatarUrl,
    bool isFediverse = false,
    String? fediverseHandle,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final profileData = {
      'id': user.id,
      'full_name': fullName,
      'username': username,
      'avatar_url': avatarUrl,
      'is_fediverse': isFediverse,
      'fediverse_handle': fediverseHandle,
      'rank': 'User',
      'created_at': DateTime.now().toIso8601String(),
    };

    await _supabase.from('profiles').upsert(profileData);
    await fetchProfile(user.id);
  }

  // Update Profile Info
  Future<void> updateProfile({
    String? fullName,
    String? bio,
    String? avatarUrl,
    String? bannerUrl,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final updates = <String, dynamic>{};
    if (fullName != null) updates['full_name'] = fullName;
    if (bio != null) updates['bio'] = bio;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    if (bannerUrl != null) updates['banner_url'] = bannerUrl;

    await _supabase.from('profiles').update(updates).eq('id', user.id);
    await fetchProfile(user.id);
  }

  // Logout
  Future<void> signOut() async {
    await _supabase.auth.signOut();
    _currentProfile = null;
    notifyListeners();
  }

  // Delete Account
  Future<void> deleteAccount() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      await _supabase.from('profiles').delete().eq('id', user.id);
      await signOut();
    }
  }
}
