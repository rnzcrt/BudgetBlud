import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import 'setup_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _supabase = SupabaseService();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();

  bool _isLoading = false;
  bool _otpSent = false;
  bool _isSignUp = false;
  String? _errorMessage;

  // Rate limiting
  DateTime? _lastOtpSentTime;
  int _otpAttempts = 0;
  static const int _maxOtpAttempts = 3;
  static const Duration _cooldownDuration = Duration(minutes: 2);

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  bool _canSendOtp() {
    if (_lastOtpSentTime == null) return true;

    final timeSinceLastAttempt = DateTime.now().difference(_lastOtpSentTime!);

    if (timeSinceLastAttempt > _cooldownDuration) {
      // Reset counter after cooldown
      _otpAttempts = 0;
      return true;
    }

    return _otpAttempts < _maxOtpAttempts;
  }

  String? _getCooldownMessage() {
    if (_lastOtpSentTime == null) return null;

    final timeSinceLastAttempt = DateTime.now().difference(_lastOtpSentTime!);

    if (_otpAttempts >= _maxOtpAttempts &&
        timeSinceLastAttempt < _cooldownDuration) {
      final remainingTime = _cooldownDuration - timeSinceLastAttempt;
      final remainingSeconds = remainingTime.inSeconds;
      return 'Too many attempts. Please wait ${remainingSeconds}s before trying again.';
    }

    return null;
  }

  Future<void> _sendOTP() async {
    // Validate email
    if (_emailController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please enter your email');
      return;
    }

    final email = _emailController.text.trim();
    if (!_isValidEmail(email)) {
      setState(() => _errorMessage = 'Please enter a valid email address');
      return;
    }

    // Check rate limiting
    final cooldownMsg = _getCooldownMessage();
    if (cooldownMsg != null) {
      setState(() => _errorMessage = cooldownMsg);
      return;
    }

    if (!_canSendOtp()) {
      setState(
        () => _errorMessage =
            'Too many attempts. Please wait before trying again.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isSignUp) {
        // Sign up flow
        await _supabase.signUpWithEmail(email);
      } else {
        // Sign in flow - check if email exists first
        final exists = await _supabase.checkEmailExists(email);

        if (!exists) {
          setState(() {
            _errorMessage =
                'No account found with this email. Please sign up first.';
            _isLoading = false;
          });
          return;
        }

        await _supabase.signInWithEmail(email);
      }

      // Track OTP attempt
      setState(() {
        _lastOtpSentTime = DateTime.now();
        _otpAttempts++;
        _otpSent = true;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Verification code sent to $email')),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _verifyOTP() async {
    final otp = _otpController.text.trim();

    if (otp.isEmpty) {
      setState(() => _errorMessage = 'Please enter the verification code');
      return;
    }

    if (otp.length != 6) {
      setState(() => _errorMessage = 'Verification code must be 6 digits');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _supabase.verifyOTP(
        email: _emailController.text.trim(),
        otp: otp,
        isSignUp: _isSignUp,
      );

      if (mounted) {
        // Success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text(_isSignUp ? 'Account created!' : 'Welcome back!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Small delay for user to see success message
        await Future.delayed(const Duration(milliseconds: 500));

        if (!mounted) return;

        // Navigate to setup screen for both signup and login
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const SetupScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resendOTP() async {
    if (!_canSendOtp()) {
      setState(
        () => _errorMessage = 'Please wait before requesting another code.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _supabase.resendOTP(_emailController.text.trim());

      setState(() {
        _lastOtpSentTime = DateTime.now();
        _otpAttempts++;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                const Text('Verification code resent!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _errorMessage = e.toString().replaceAll('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Logo
              Image.asset("images/budget_blud.png", width: 100),
              const SizedBox(height: 20),

              // Title
              Text(
                _otpSent
                    ? 'Verify Code'
                    : (_isSignUp ? 'Create Account' : 'Welcome Back'),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Subtitle
              Text(
                _otpSent
                    ? 'Enter the 6-digit code sent to your email'
                    : (_isSignUp
                          ? 'Sign up to get started'
                          : 'Login to continue'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Form Fields
              if (!_otpSent) ...[
                // Email field
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    filled: true,
                    fillColor: isDark ? Colors.grey[800] : Colors.blue[50],
                  ),
                ),
              ] else ...[
                // OTP field
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Verification Code',
                    hintText: '000000',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white38 : Colors.grey[400],
                      letterSpacing: 8,
                    ),
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    filled: true,
                    fillColor: isDark ? Colors.grey[800] : Colors.blue[50],
                    counterText: '',
                  ),
                  onChanged: (value) {
                    if (value.length == 6) {
                      _verifyOTP();
                    }
                  },
                ),
              ],

              const SizedBox(height: 16),

              // Error message
              if (_errorMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Colors.red[700],
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Main action button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : (_otpSent ? _verifyOTP : _sendOTP),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    disabledBackgroundColor: Colors.grey,
                    padding: const EdgeInsets.symmetric(vertical: 21),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _otpSent
                              ? 'Verify'
                              : (_isSignUp ? 'Sign Up' : 'Login'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              // Resend OTP button
              if (_otpSent) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Didn't receive the code? ",
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    TextButton(
                      onPressed: _isLoading || !_canSendOtp()
                          ? null
                          : _resendOTP,
                      child: Text(
                        _canSendOtp() ? 'Resend' : 'Please wait...',
                        style: TextStyle(
                          color: _canSendOtp()
                              ? const Color(0xFF2563EB)
                              : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const Spacer(),

              // Toggle between Sign In and Sign Up
              if (!_otpSent)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isSignUp
                          ? "Already have an account? "
                          : "Don't have an account? ",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isSignUp = !_isSignUp;
                          _errorMessage = null;
                        });
                      },
                      child: Text(
                        _isSignUp ? 'Login' : 'Sign Up',
                        style: const TextStyle(
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
