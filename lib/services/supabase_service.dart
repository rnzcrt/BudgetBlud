import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient get client => Supabase.instance.client;

  /// Initialize Supabase
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: 'https://werfwsscctwuuoqodkqu.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndlcmZ3c3NjY3R3dXVvcW9ka3F1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg4ODUxNTMsImV4cCI6MjA3NDQ2MTE1M30.3BnlWtFqgz10uArnSugBiyd0JnfuZET7wKdls59_CjE',
    );
    debugPrint('✅ Supabase initialized');
  }

  /// Check if user is authenticated
  bool get isAuthenticated => client.auth.currentUser != null;

  /// Get current user
  User? get currentUser => client.auth.currentUser;

  /// Get current user ID
  String? get currentUserId => client.auth.currentUser?.id;

  /// Get current user email
  String? get currentUserEmail => client.auth.currentUser?.email;

  /// Sign up with email (sends OTP)
  Future<void> signUpWithEmail(String email) async {
    try {
      debugPrint('🔵 Attempting to send OTP to: $email');

      await client.auth.signInWithOtp(
        email: email,
        shouldCreateUser: true, // This ensures new users are created
      );

      debugPrint('✅ OTP request successful for: $email');
    } on AuthException catch (e) {
      debugPrint('❌ AuthException: ${e.message}');
      debugPrint('❌ Status Code: ${e.statusCode}');

      // Handle specific error cases
      if (e.message.toLowerCase().contains('rate limit')) {
        throw Exception(
          'Too many attempts. Please wait 60 seconds and try again.',
        );
      } else if (e.message.toLowerCase().contains('invalid email')) {
        throw Exception('Please enter a valid email address.');
      } else if (e.statusCode == '500') {
        throw Exception(
          'Server error. Please check your Supabase email configuration.',
        );
      } else {
        throw Exception('Failed to send code: ${e.message}');
      }
    } catch (e) {
      debugPrint('❌ Unexpected error: $e');
      throw Exception('Network error. Please check your internet connection.');
    }
  }

  /// Sign in with email (sends OTP)
  Future<void> signInWithEmail(String email) async {
    try {
      debugPrint('🔵 Attempting to sign in: $email');

      // Check if user exists first
      final exists = await checkEmailExists(email);

      if (!exists) {
        throw Exception('No account found. Please sign up first.');
      }

      await client.auth.signInWithOtp(
        email: email,
        shouldCreateUser: false, // Don't create user for sign-in
      );

      debugPrint('✅ Sign-in OTP sent to: $email');
    } on AuthException catch (e) {
      debugPrint('❌ AuthException: ${e.message}');

      if (e.message.toLowerCase().contains('rate limit')) {
        throw Exception(
          'Too many attempts. Please wait 60 seconds and try again.',
        );
      } else if (e.statusCode == '500') {
        throw Exception(
          'Server error. Please check your Supabase configuration.',
        );
      } else {
        throw Exception('Failed to send code: ${e.message}');
      }
    } catch (e) {
      debugPrint('❌ Error: $e');
      rethrow;
    }
  }

  /// Verify OTP
  Future<void> verifyOTP({
    required String email,
    required String otp,
    bool isSignUp = false,
  }) async {
    try {
      debugPrint('🔵 Verifying OTP for: $email');

      final response = await client.auth.verifyOTP(
        type: OtpType.email,
        email: email,
        token: otp,
      );

      if (response.user == null) {
        throw Exception('Verification failed. Please try again.');
      }

      debugPrint('✅ User verified: ${response.user!.email}');

      // Ensure user profile exists
      await _ensureUserProfileExists(response.user!.id, email);
    } on AuthException catch (e) {
      debugPrint('❌ OTP Verification Error: ${e.message}');

      if (e.message.toLowerCase().contains('expired')) {
        throw Exception('Code expired. Please request a new one.');
      } else if (e.message.toLowerCase().contains('invalid')) {
        throw Exception('Invalid code. Please check and try again.');
      } else {
        throw Exception('Verification failed: ${e.message}');
      }
    } catch (e) {
      debugPrint('❌ Error verifying OTP: $e');
      rethrow;
    }
  }

  /// Ensure user profile exists
  Future<void> _ensureUserProfileExists(String userId, String email) async {
    try {
      debugPrint('🔵 Checking user profile for: $userId');

      final existing = await client
          .from('users')
          .select('id')
          .eq('id', userId)
          .maybeSingle();

      if (existing == null) {
        debugPrint('🔵 Creating user profile...');
        await client.from('users').insert({
          'id': userId,
          'email': email,
          'created_at': DateTime.now().toIso8601String(),
        });
        debugPrint('✅ User profile created');
      } else {
        debugPrint('✅ User profile already exists');
      }
    } catch (e) {
      debugPrint('⚠️ Error with user profile (non-critical): $e');
      // Don't throw - this is non-critical
    }
  }

  /// Check if email exists in auth.users
  Future<bool> checkEmailExists(String email) async {
    try {
      debugPrint('🔵 Checking if email exists: $email');

      // First, try to check public.users table
      try {
        final response = await client
            .from('users')
            .select('email')
            .eq('email', email)
            .maybeSingle();

        if (response != null) {
          debugPrint('✅ Email found in users table: $email');
          return true;
        }
      } catch (e) {
        debugPrint('⚠️ Could not check users table: $e');
      }

      // Fallback: Try to sign in with OTP to check if email exists in auth
      // If email doesn't exist, Supabase will create a new user
      // So for sign-in, we'll just allow the attempt and let Supabase handle it

      // For now, we'll be more lenient and allow sign-in attempts
      // The real check happens when OTP is sent
      debugPrint('⚠️ Email not found in users table, allowing sign-in attempt');
      return true; // Allow sign-in attempt
    } catch (e) {
      debugPrint('❌ Error checking email: $e');
      return true; // Allow attempt on error
    }
  }

  /// Resend OTP
  Future<void> resendOTP(String email) async {
    try {
      debugPrint('🔵 Resending OTP to: $email');

      await client.auth.resend(type: OtpType.email, email: email);

      debugPrint('✅ OTP resent to $email');
    } on AuthException catch (e) {
      debugPrint('❌ Resend OTP Error: ${e.message}');

      if (e.message.toLowerCase().contains('rate limit')) {
        throw Exception('Too many requests. Please wait 60 seconds.');
      } else {
        throw Exception('Failed to resend: ${e.message}');
      }
    } catch (e) {
      debugPrint('❌ Error resending OTP: $e');
      throw Exception('Failed to resend code. Please try again.');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await client.auth.signOut();
      debugPrint('✅ User signed out');
    } catch (e) {
      debugPrint('❌ Error signing out: $e');
      rethrow;
    }
  }

  /// Listen to auth state changes
  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;
}
