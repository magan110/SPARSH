import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/io_client.dart';
import 'package:learning2/core/theme/app_theme.dart';
import 'package:learning2/core/widgets/modern_card.dart';
import 'package:learning2/core/widgets/modern_button.dart';
import 'package:learning2/core/widgets/modern_input.dart';
import 'package:learning2/features/worker/presentation/pages/Worker_Home_Screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:learning2/features/dashboard/presentation/pages/home_screen.dart';
import 'log_in_otp.dart';
import 'package:learning2/core/constants/fonts.dart';

class LoginScreen extends StatefulWidget {
  final bool fromSplash;

  const LoginScreen({super.key, this.fromSplash = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final String apiUrl = "https://192.168.55.182:7023/api/Auth/login";
  bool _obscurePassword = true;
  bool _isLoading = false;
  final bool _rememberMe = false;
  late FirebaseMessaging _messaging;
  String? _deviceToken;
  final _formKey = GlobalKey<FormState>();

  // Animation controllers
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeFirebaseMessaging();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeIn),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
      ),
    );

    _animController.forward();
  }

  void _initializeFirebaseMessaging() async {
    _messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    _deviceToken = await _messaging.getToken();
  }

  Future<void> loginUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final String userID = _usernameController.text.trim();
    final String password = _passwordController.text.trim();
    final String appRegId = _deviceToken ?? "UnknownDevice";

    final Map<String, dynamic> requestBody = {
      'userID': userID,
      'password': password,
      'appRegId': appRegId,
    };

    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isEmpty || result.first.rawAddress.isEmpty) {
        throw const SocketException('No Internet Connection');
      }

      final client = IOClient(
        HttpClient()..badCertificateCallback = (cert, host, port) => true,
      );
      final response = await client.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['msg'] == 'Authentication successful') {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);

          final String role = responseData['role'] ?? '';

          // Navigate based on role
          Widget nextScreen;
          switch (role) {
            case 'Worker':
              nextScreen = const WorkerHomeScreen();
              break;
            case 'Customer':
              nextScreen = const HomeScreen();
              break;
            default:
              nextScreen = const HomeScreen();
          }

          if (mounted) {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 500),
                pageBuilder: (_, __, ___) => nextScreen,
                transitionsBuilder: (_, animation, __, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
              ),
            );
          }
        } else {
          _showErrorDialog(
            "Authentication failed. Please check your credentials.",
          );
        }
      } else {
        _showErrorDialog("Failed to authenticate. Please try again.");
      }
      client.close();
    } on SocketException catch (_) {
      _showErrorDialog(
        'No Internet Connection\nPlease check your connection and try again.',
      );
    } catch (e) {
      _showErrorDialog('An error occurred: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
        title: const Text('Error', style: TextStyle(color: Colors.red)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Colors.blue)),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade900,
              Colors.blue.shade800,
              Colors.blue.shade700,
            ],
          ),
        ),
        child: Stack(
          children: [
            // Background design elements
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -80,
              left: -80,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // Main content with animations
            AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                return SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: child,
                    ),
                  ),
                );
              },
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // App Logo/Icon
                      Container(
                        width: 250,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 15,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Image.asset(
                          'assets/logo.png',
                          fit: BoxFit.fill,
                        ),
                      ),
                      const SizedBox(height: 30),

                      // App Name
                      ShaderMask(
                        shaderCallback:
                            (bounds) => LinearGradient(
                          colors: [
                            Colors.white,
                            Colors.white.withOpacity(0.8),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ).createShader(bounds),
                        child: Text(
                          'SPARSH',
                          style: Fonts.bodyBold.copyWith(
                            fontSize: 36,
                            color: Colors.white,
                            letterSpacing: 4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Login Card
                      ModernCard(
                        padding: const EdgeInsets.all(SparshTheme.spacing32),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome Back',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: SparshTheme.primaryBlue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: SparshTheme.spacing8),
                              Text(
                                'Sign in to continue',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: SparshTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: SparshTheme.spacing32),

                              // Username Field
                              ModernInput(
                                label: 'Username',
                                controller: _usernameController,
                                prefixIcon: const Icon(Icons.person_outline, color: SparshTheme.primaryBlue),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your username';
                                  }
                                  return null;
                                },
                                inputFormatters: [
                                  FilteringTextInputFormatter.deny(RegExp(r'\s')),
                                ],
                              ),
                              const SizedBox(height: SparshTheme.spacing20),

                              // Password Field
                              ModernInput(
                                label: 'Password',
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                prefixIcon: const Icon(Icons.lock_outline, color: SparshTheme.primaryBlue),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                    color: SparshTheme.textSecondary,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your password';
                                  }
                                  if (value.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: SparshTheme.spacing16),

                              // Forgot Password
                              Align(
                                alignment: Alignment.centerRight,
                                child: ModernButton(
                                  text: 'Forgot Password?',
                                  onPressed: () {
                                    // Forgot password functionality
                                  },
                                  type: ModernButtonType.text,
                                ),
                              ),
                              const SizedBox(height: SparshTheme.spacing24),

                              // Login Button
                              ModernButton(
                                text: 'LOGIN',
                                onPressed: _isLoading ? null : loginUser,
                                isLoading: _isLoading,
                                isFullWidth: true,
                                type: ModernButtonType.primary,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // OTP Login Option
                      const SizedBox(height: SparshTheme.spacing20),
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: SparshTheme.spacing20),
                        child: ModernButton(
                          text: 'Login with OTP',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LogInOtp(),
                              ),
                            );
                          },
                          type: ModernButtonType.outline,
                          icon: const Icon(Icons.phone_android),
                          isFullWidth: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
