import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// Supabase Authentication Service
/// Replaces Firebase Auth with Supabase Auth
class SupabaseAuthService {
  final SupabaseClient _client = SupabaseConfig.client;

  /// Get current user
  User? get currentUser => _client.auth.currentUser;

  /// Get current user ID
  String? get currentUserId => currentUser?.id;

  /// Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  /// Get auth state changes stream
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // ============================================
  // AUTHENTICATION METHODS
  // ============================================

  /// Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'display_name': displayName ?? email.split('@')[0]},
    );

    // Create user profile in database
    if (response.user != null) {
      await _createUserProfile(
        userId: response.user!.id,
        email: email,
        displayName: displayName ?? email.split('@')[0],
      );
    }

    return response;
  }

  /// Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    // Ensure user profile exists in database
    if (response.user != null) {
      await _ensureUserProfile(
        userId: response.user!.id,
        email: email,
        displayName:
            response.user!.userMetadata?['display_name'] ?? email.split('@')[0],
      );
    }

    return response;
  }

  /// Sign out
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Send password reset email
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  /// Update password (requires current session)
  Future<UserResponse> updatePassword(String newPassword) async {
    return await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  /// Update email (requires current session)
  Future<UserResponse> updateEmail(String newEmail) async {
    return await _client.auth.updateUser(UserAttributes(email: newEmail));
  }

  /// Update display name
  Future<void> updateDisplayName(String displayName) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Not authenticated');

    // Update in auth metadata
    await _client.auth.updateUser(
      UserAttributes(data: {'display_name': displayName}),
    );

    // Update in users table
    await _client
        .from('users')
        .update({
          'display_name': displayName,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', userId);
  }

  /// Update photo URL
  Future<void> updatePhotoUrl(String photoUrl) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Not authenticated');

    // Update in auth metadata
    await _client.auth.updateUser(
      UserAttributes(data: {'photo_url': photoUrl}),
    );

    // Update in users table
    await _client
        .from('users')
        .update({
          'photo_url': photoUrl,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', userId);
  }

  /// Delete account
  Future<void> deleteAccount() async {
    // Note: Requires service role key in production
    // For now, just sign out
    await signOut();
  }

  // ============================================
  // USER PROFILE METHODS
  // ============================================

  /// Create user profile in database
  Future<void> _createUserProfile({
    required String userId,
    required String email,
    required String displayName,
  }) async {
    await _client.from('users').insert({
      'id': userId,
      'email': email,
      'display_name': displayName,
      'is_online': true,
      'last_seen': DateTime.now().toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Ensure user profile exists (create if not exists, update if exists)
  Future<void> _ensureUserProfile({
    required String userId,
    required String email,
    required String displayName,
  }) async {
    try {
      // Use UPSERT to create or update user profile
      await _client.from('users').upsert({
        'id': userId,
        'email': email,
        'display_name': displayName,
        'is_online': true,
        'last_seen': DateTime.now().toIso8601String(),
      }, onConflict: 'id');

      print('✅ User profile ensured for: $email');
    } catch (e) {
      print('❌ Failed to ensure user profile: $e');
      // Re-throw to let caller handle
      rethrow;
    }
  }

  /// Get user profile
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final response = await _client
        .from('users')
        .select()
        .eq('id', userId)
        .maybeSingle();

    return response;
  }

  /// Update online status
  Future<void> updateOnlineStatus(bool isOnline) async {
    final userId = currentUserId;
    if (userId == null) return;

    await _client
        .from('users')
        .update({
          'is_online': isOnline,
          'last_seen': DateTime.now().toIso8601String(),
        })
        .eq('id', userId);
  }

  // ============================================
  // RE-AUTHENTICATION (for sensitive operations)
  // ============================================

  /// Re-authenticate user with password (for email/password changes)
  Future<bool> reauthenticate(String password) async {
    final user = currentUser;
    if (user == null || user.email == null) return false;

    try {
      // Sign in again to verify password
      await _client.auth.signInWithPassword(
        email: user.email!,
        password: password,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  // ============================================
  // HELPER METHODS
  // ============================================

  /// Get user metadata
  Map<String, dynamic>? get userMetadata => currentUser?.userMetadata;

  /// Get display name from metadata or email
  String get displayName {
    final metadata = userMetadata;
    if (metadata != null && metadata['display_name'] != null) {
      return metadata['display_name'];
    }
    return currentUser?.email?.split('@')[0] ?? 'User';
  }

  /// Get photo URL from metadata
  String? get photoUrl {
    final metadata = userMetadata;
    if (metadata != null && metadata['photo_url'] != null) {
      return metadata['photo_url'];
    }
    return null;
  }
}
