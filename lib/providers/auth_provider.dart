import 'dart:io';
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

  // Verifica se un'email ha già un profilo o un account registrato interrogando Supabase
  Future<Map<String, dynamic>> checkUserStatus(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    try {
      final res = await _supabase
          .from('profiles')
          .select()
          .eq('email', cleanEmail)
          .maybeSingle();
      
      if (res != null) {
        final profile = UserProfile.fromJson(res);
        return {
          'exists': true,
          'isOnboardingCompleted': profile.isOnboardingCompleted,
        };
      }
      return {'exists': false, 'isOnboardingCompleted': false};
    } catch (e) {
      debugPrint('Error checking user email status: $e');
      return {'exists': false, 'isOnboardingCompleted': false};
    }
  }

  Future<bool> checkUsernameExists(String username) async {
    try {
      final res = await _supabase
          .from('profiles')
          .select('id')
          .eq('username', username.trim().toLowerCase())
          .maybeSingle();
      return res != null;
    } catch (e) {
      return false;
    }
  }

  // Password reset email request
  Future<void> sendPasswordResetEmail(String email) async {
    await _supabase.auth.resetPasswordForEmail(email.trim());
  }

  // Secure email change
  Future<void> updateEmailSecure(String newEmail) async {
    await _supabase.auth.updateUser(
      UserAttributes(email: newEmail.trim()),
    );
  }

  // Upload Avatar to 'ProfilePic' storage bucket (supports GIF in loop)
  Future<String?> uploadAvatarToProfilePicBucket(String localFilePath) async {
    final user = _supabase.auth.currentUser;
    final userId = user?.id ?? _currentProfile?.id ?? 'guest';
    
    try {
      final file = File(localFilePath);
      if (!await file.exists()) return localFilePath;

      final extension = localFilePath.split('.').last.toLowerCase();
      final fileName = '$userId-${DateTime.now().millisecondsSinceEpoch}.$extension';
      
      final storagePath = 'avatars/$fileName';
      
      await _supabase.storage.from('ProfilePic').upload(
        storagePath,
        file,
        fileOptions: FileOptions(
          upsert: true,
          contentType: extension == 'gif' ? 'image/gif' : 'image/$extension',
        ),
      );

      final publicUrl = _supabase.storage.from('ProfilePic').getPublicUrl(storagePath);
      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading avatar to ProfilePic bucket: $e');
      return localFilePath;
    }
  }

  // Autenticazione / Registrazione ActivityPub Dinamica con Supabase profiles
  Future<UserProfile> loginOrRegisterFediverseProfile(Map<String, dynamic> fediverseData) async {
    _isLoading = true;
    notifyListeners();
    try {
      final handle = fediverseData['fediverse_handle'] as String;

      // Cerca se esiste già nel DB Supabase per fediverse_handle
      final res = await _supabase
          .from('profiles')
          .select()
          .eq('fediverse_handle', handle)
          .maybeSingle();

      final cleanHandle = handle.replaceAll('@', '_').replaceAll('.', '_').toLowerCase();
      final syntheticEmail = '$cleanHandle@fediverse.feditok';
      final syntheticPassword = 'Feditok_${cleanHandle}_Secret!';

      var user = _supabase.auth.currentUser;
      if (user == null) {
        try {
          final authRes = await _supabase.auth.signInWithPassword(
            email: syntheticEmail,
            password: syntheticPassword,
          );
          user = authRes.user;
        } catch (_) {
          try {
            final authRes = await _supabase.auth.signUp(
              email: syntheticEmail,
              password: syntheticPassword,
            );
            user = authRes.user;
          } catch (signUpErr) {
            debugPrint('Notice on Fediverse synthetic auth signup: $signUpErr');
          }
        }
      }

      if (res != null) {
        _currentProfile = UserProfile.fromJson(res);
        return _currentProfile!;
      } else {
        final profileId = user?.id;

        final newProfileMap = <String, dynamic>{
          if (profileId != null) 'id': profileId,
          'username': (fediverseData['username'] as String).toLowerCase(),
          'full_name': fediverseData['full_name'],
          'avatar_url': fediverseData['avatar_url'],
          'banner_url': fediverseData['banner_url'],
          'bio': fediverseData['bio'],
          'is_fediverse': true,
          'fediverse_handle': handle,
          'rank': 'User',
          'is_onboarding_completed': true,
          'created_at': DateTime.now().toIso8601String(),
        };

        // Inserimento o upsert nel DB Supabase
        final inserted = await _supabase
            .from('profiles')
            .upsert(newProfileMap)
            .select()
            .single();

        _currentProfile = UserProfile.fromJson(inserted);
        return _currentProfile!;
      }
    } catch (e) {
      debugPrint('Error syncing Fediverse profile to Supabase: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
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

  // Email / Password Sign Up (Inserisce subito i primi dati nel DB per evitare falsi negativi sul check email)
  Future<User?> signUpWithEmail(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      
      final user = response.user;
      if (user != null) {
        final cleanEmail = email.trim().toLowerCase();
        final defaultUsername = cleanEmail.split('@').first;

        // Inserimento immediato dei primi dati nel DB profiles
        final initialProfileMap = {
          'id': user.id,
          'email': cleanEmail,
          'username': defaultUsername,
          'rank': 'User',
          'is_onboarding_completed': false,
          'created_at': DateTime.now().toIso8601String(),
        };

        await _supabase.from('profiles').upsert(initialProfileMap);
        await fetchProfile(user.id);
      }
      return user;
    } catch (e) {
      debugPrint('Error signing up user and creating initial profile: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Salva l'onboarding dell'utente e imposta is_onboarding_completed = true
  Future<void> completeOnboarding({
    required String fullName,
    required String username,
    String? avatarUrl,
    bool isFediverse = false,
    String? fediverseHandle,
  }) async {
    final user = _supabase.auth.currentUser;
    // RISOLUZIONE BUG #5: Usa SEMPRE l'UUID valido di auth.currentUser se presente
    final userId = user?.id;

    if (userId == null) {
      throw Exception("Utente non autenticato. Impossibile completare l'onboarding senza un ID utente valido.");
    }

    String? uploadedAvatarPublicUrl = avatarUrl;
    if (avatarUrl != null && !avatarUrl.startsWith('http')) {
      uploadedAvatarPublicUrl = await uploadAvatarToProfilePicBucket(avatarUrl);
    }

    final userEmail = user?.email;

    final profileData = {
      'id': userId,
      'email': userEmail?.trim().toLowerCase(),
      'full_name': fullName,
      'username': username.trim().toLowerCase(),
      'avatar_url': uploadedAvatarPublicUrl,
      'is_fediverse': isFediverse,
      'fediverse_handle': fediverseHandle,
      'rank': 'User',
      'is_onboarding_completed': true, // Impostato a true alla fine!
      'created_at': DateTime.now().toIso8601String(),
    };

    await _supabase.from('profiles').upsert(profileData);
    await fetchProfile(userId);
    notifyListeners();
  }

  // Update Profile Info
  Future<void> updateProfile({
    String? username,
    String? fullName,
    String? bio,
    String? avatarUrl,
    String? bannerUrl,
  }) async {
    final user = _supabase.auth.currentUser;
    final currentId = user?.id ?? _currentProfile?.id;
    if (currentId == null) return;

    final updates = <String, dynamic>{};
    if (username != null) updates['username'] = username.trim().toLowerCase();
    if (fullName != null) updates['full_name'] = fullName;
    if (bio != null) updates['bio'] = bio;

    if (avatarUrl != null) {
      if (!avatarUrl.startsWith('http')) {
        updates['avatar_url'] = await uploadAvatarToProfilePicBucket(avatarUrl);
      } else {
        updates['avatar_url'] = avatarUrl;
      }
    }

    if (bannerUrl != null) updates['banner_url'] = bannerUrl;

    await _supabase.from('profiles').update(updates).eq('id', currentId);
    await fetchProfile(currentId);
  }

  // Logout
  Future<void> signOut() async {
    await _supabase.auth.signOut();
    _currentProfile = null;
    notifyListeners();
  }

  // Delete Account
  Future<void> deleteAccount() async {
    final currentId = _supabase.auth.currentUser?.id ?? _currentProfile?.id;
    if (currentId != null) {
      await _supabase.from('profiles').delete().eq('id', currentId);
      await signOut();
    }
  }
}
