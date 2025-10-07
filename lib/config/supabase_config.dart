import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase Configuration
///
/// Replace these values with your actual Supabase project credentials
/// Get them from: https://app.supabase.com/project/_/settings/api
class SupabaseConfig {
  // ⚠️ REPLACE WITH YOUR ACTUAL VALUES
  static const String supabaseUrl = 'https://hqurumleoygxrhkuvahg.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhxdXJ1bWxlb3lneHJoa3V2YWhnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk3NTQ5MTAsImV4cCI6MjA3NTMzMDkxMH0.SGA9MgO_VhUvO2Skq6kZ0Txb91EiFOHplgG3ni8pJWc';

  // Don't commit this to git! Use environment variables in production
  static const String supabaseServiceRoleKey =
      'YOUR_SERVICE_ROLE_KEY_HERE'; // Only for migration scripts

  /// Initialize Supabase
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      debug: true, // Set to false in production
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  }

  /// Get Supabase client
  static SupabaseClient get client => Supabase.instance.client;

  /// Get authenticated user ID
  static String? get currentUserId =>
      Supabase.instance.client.auth.currentUser?.id;

  /// Check if user is authenticated
  static bool get isAuthenticated =>
      Supabase.instance.client.auth.currentUser != null;
}
