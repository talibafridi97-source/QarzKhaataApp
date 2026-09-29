import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/khaata_provider.dart';
import '../widgets/biometric_dialog.dart';

/// Screen for User Onboarding, Sign Up (Name, Email, PIN), Login, Biometric Unlock, and Multi-Language support.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _pinController = TextEditingController();

  bool _isSignUpMode = true;

  @override
  void initState() {
    super.initState();
    final provider = context.read<KhaataProvider>();
    if (provider.hasAccount) {
      _isSignUpMode = false;
      _nameController.text = provider.userName;
      _emailController.text = provider.userEmail;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  /// Normal Submit (Sign Up or Login with PIN/Email)
  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<KhaataProvider>();

    if (_isSignUpMode) {
      final success = await provider.signUp(
        name: _nameController.text,
        email: _emailController.text,
        pin: _pinController.text,
      );
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome to ${provider.businessName}!'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } else {
      final success = await provider.login(_pinController.text);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logged in as ${provider.businessName}'),
            backgroundColor: Colors.indigo,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Incorrect PIN/Password. Please try again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  /// Biometric Fingerprint Auth (for Sign Up or Login verification)
  void _tryBiometric() async {
    final provider = context.read<KhaataProvider>();
    
    if (_isSignUpMode && (_nameController.text.trim().isEmpty || _emailController.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your Name and Email first before using fingerprint signup.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Explicitly show Biometric Fingerprint verification dialog
    final bool scanned = await BiometricDialog.show(context);
    if (!mounted) return;

    if (scanned) {
      if (_isSignUpMode) {
        await provider.signUp(
          name: _nameController.text,
          email: _emailController.text,
          pin: _pinController.text.trim().isEmpty ? '1234' : _pinController.text,
        );
      } else {
        await provider.login(provider.userPin);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fingerprint verified successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fingerprint verification failed. Login failed.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<KhaataProvider>();
    final l10n = AppLocalizations(provider.locale);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Language Selector at Top Right
              Positioned(
                top: 12,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(35),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButton<String>(
                    value: provider.locale,
                    dropdownColor: const Color(0xFF1E3C72),
                    underline: const SizedBox(),
                    icon: const Icon(Icons.language_rounded, color: Colors.white),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    items: const [
                      DropdownMenuItem(value: 'en', child: Text('English')),
                      DropdownMenuItem(value: 'ur', child: Text('اردو')),
                      DropdownMenuItem(value: 'ps', child: Text('پښتو')),
                      DropdownMenuItem(value: 'ar', child: Text('العربية')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        provider.setLocale(val);
                      }
                    },
                  ),
                ),
              ),

              // Main Auth Form Box
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // App Icon Branding Header
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(35),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.menu_book_rounded,
                          size: 56,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'QARZ KHAATA',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const Text(
                        'Digital Micro-Business Ledger',
                        style: TextStyle(fontSize: 14, color: Colors.white70),
                      ),
                      const SizedBox(height: 32),

                      // Auth Card Box
                      Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header Switch & Login/Signup Switch Button
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _isSignUpMode ? l10n.translate('signup') : l10n.translate('login'),
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E3C72),
                                      ),
                                    ),
                                    TextButton.icon(
                                      style: TextButton.styleFrom(foregroundColor: Colors.indigo),
                                      onPressed: () {
                                        setState(() {
                                          _isSignUpMode = !_isSignUpMode;
                                          _pinController.clear();
                                        });
                                      },
                                      icon: Icon(_isSignUpMode ? Icons.login_rounded : Icons.person_add_rounded, size: 18),
                                      label: Text(
                                        _isSignUpMode ? 'Already have account? Login' : 'New User? Sign Up',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 24),

                                // Sign Up Fields (Name, Email, PIN)
                                if (_isSignUpMode) ...[
                                  TextFormField(
                                    controller: _nameController,
                                    textCapitalization: TextCapitalization.words,
                                    decoration: InputDecoration(
                                      labelText: 'Your Name *',
                                      hintText: 'e.g. Talibjan',
                                      prefixIcon: const Icon(Icons.person_rounded),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) {
                                        return 'Please enter your name';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),

                                  // Email Field
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: InputDecoration(
                                      labelText: 'Email Address *',
                                      hintText: 'e.g. talibjan@gmail.com',
                                      prefixIcon: const Icon(Icons.email_outlined),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) {
                                        return 'Please enter email address';
                                      }
                                      if (!v.contains('@') || !v.contains('.')) {
                                        return 'Please enter a valid email address';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                ] else ...[
                                  Text(
                                    '${l10n.translate('welcome_back')}, ${provider.userName.isNotEmpty ? provider.userName : "User"}!',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    'Header: ${provider.businessName}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],

                                // PIN / Security Code Field
                                TextFormField(
                                  controller: _pinController,
                                  keyboardType: TextInputType.number,
                                  obscureText: true,
                                  decoration: InputDecoration(
                                    labelText: l10n.translate('pin_code'),
                                    hintText: 'e.g. 1234',
                                    prefixIcon: const Icon(Icons.lock_rounded),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  validator: (v) {
                                    if (_isSignUpMode && (v == null || v.trim().isEmpty)) {
                                      return 'Please enter a security PIN';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 24),

                                // Action Button (Create My Khaata / Login)
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1E3C72),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 2,
                                    ),
                                    onPressed: _submit,
                                    child: Text(
                                      _isSignUpMode
                                          ? l10n.translate('create_khaata')
                                          : l10n.translate('login'),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),

                                // Biometric Fingerprint Button
                                const SizedBox(height: 16),
                                Center(
                                  child: TextButton.icon(
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.indigo,
                                    ),
                                    onPressed: _tryBiometric,
                                    icon: const Icon(Icons.fingerprint_rounded, size: 28),
                                    label: Text(
                                      _isSignUpMode ? 'Sign Up with Fingerprint' : 'Forgot PIN? Login with Fingerprint',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
