import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/khaata_provider.dart';

/// Screen for User Onboarding, Sign Up (Name, Email, PIN, Profile Picture), Login, and Biometrics.
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
  final _loginPinController = TextEditingController();

  String? _selectedImagePath;
  bool _isSignUpMode = true;
  bool _isProcessing = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final provider = context.read<KhaataProvider>();
    if (provider.hasLocalUser) {
      _isSignUpMode = false;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _pinController.dispose();
    _loginPinController.dispose();
    super.dispose();
  }

  /// Open bottom sheet to choose Camera or Gallery for profile picture
  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Select Profile Picture',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF1E3C72),
                    child: Icon(Icons.camera_alt_rounded, color: Colors.white),
                  ),
                  title: const Text('Take a Photo (Camera)'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _getImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF2A5298),
                    child: Icon(Icons.photo_library_rounded, color: Colors.white),
                  ),
                  title: const Text('Choose from Gallery'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _getImage(ImageSource.gallery);
                  },
                ),
                if (_selectedImagePath != null)
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.redAccent,
                      child: Icon(Icons.delete_outline_rounded, color: Colors.white),
                    ),
                    title: const Text('Remove Photo', style: TextStyle(color: Colors.redAccent)),
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _selectedImagePath = null;
                      });
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _getImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImagePath = pickedFile.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  /// 1. Standard Sign Up with Name, Email, PIN ("Create Your Qarz Khaata")
  Future<void> _submitSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);
    final provider = context.read<KhaataProvider>();

    final success = await provider.signUpWithPin(
      name: _nameController.text,
      email: _emailController.text,
      pin: _pinController.text,
      profilePicPath: _selectedImagePath,
    );

    if (mounted) {
      setState(() => _isProcessing = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome to ${provider.businessName}!'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create account. Please try again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  /// 2. Sign Up with Fingerprint ("Sign Up with Fingerprint")
  Future<void> _signUpWithFingerprint() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);
    final provider = context.read<KhaataProvider>();

    final success = await provider.signUpWithFingerprint(
      name: _nameController.text,
      email: _emailController.text,
      pin: _pinController.text.trim().isEmpty ? '1234' : _pinController.text,
      profilePicPath: _selectedImagePath,
    );

    if (mounted) {
      setState(() => _isProcessing = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Account created & biometric secured for ${provider.businessName}!'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Biometric sign up failed or canceled.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  /// 3. Standard Login with Email and PIN ("Login")
  Future<void> _submitLogin() async {
    if (_loginPinController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your PIN to login'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isProcessing = true);
    final provider = context.read<KhaataProvider>();

    final success = await provider.loginWithPin(_loginPinController.text);

    if (mounted) {
      setState(() => _isProcessing = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logged in successfully to ${provider.businessName}'),
            backgroundColor: Colors.indigo,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Incorrect PIN. Please try again or use fingerprint.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  /// 4. Login with Fingerprint ("Login with Fingerprint")
  Future<void> _loginWithFingerprint() async {
    setState(() => _isProcessing = true);
    final provider = context.read<KhaataProvider>();

    final user = await provider.loginWithFingerprint();

    if (mounted) {
      setState(() => _isProcessing = false);
      if (user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fingerprint verified! Logged in as ${provider.businessName}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fingerprint verification failed or biometric login not enabled.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
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
                        elevation: 10,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: _isSignUpMode
                              ? _buildSignUpForm(provider, l10n)
                              : _buildLoginForm(provider, l10n),
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

  /// Sign Up Form: Name, Email, PIN, and Both Action Buttons
  Widget _buildSignUpForm(KhaataProvider provider, AppLocalizations l10n) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.translate('signup'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3C72),
                ),
              ),
              if (provider.hasLocalUser)
                TextButton.icon(
                  onPressed: () {
                    setState(() => _isSignUpMode = false);
                  },
                  icon: const Icon(Icons.login_rounded, size: 16),
                  label: const Text('Go to Login', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const Divider(height: 20),

          // Profile Picture Picker
          GestureDetector(
            onTap: _pickImage,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 46,
                  backgroundColor: const Color(0xFF1E3C72).withAlpha(25),
                  backgroundImage: _selectedImagePath != null && !kIsWeb
                      ? FileImage(File(_selectedImagePath!))
                      : null,
                  child: _selectedImagePath == null
                      ? const Icon(Icons.person_rounded, size: 50, color: Color(0xFF1E3C72))
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1E3C72),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _selectedImagePath == null ? 'Tap to choose Profile Picture' : 'Tap to change photo',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),

          // Name Input
          TextFormField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Full Name *',
              hintText: 'e.g. Talib Afridi',
              prefixIcon: const Icon(Icons.person_outline_rounded),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Please enter your name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Email Input
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email Address *',
              hintText: 'e.g. user@example.com',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Please enter your email';
              }
              if (!v.contains('@') || !v.contains('.')) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // PIN Input
          TextFormField(
            controller: _pinController,
            keyboardType: TextInputType.number,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Security PIN *',
              hintText: 'e.g. 1234',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Please enter a 4-digit PIN';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Button 1: "Create Your Qarz Khaata"
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3C72),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 3,
              ),
              onPressed: _isProcessing ? null : _submitSignup,
              child: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Create Your Qarz Khaata',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
          const SizedBox(height: 12),

          // Button 2: "Sign Up with Fingerprint"
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1E3C72),
                side: const BorderSide(color: Color(0xFF1E3C72), width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: _isProcessing ? null : _signUpWithFingerprint,
              icon: const Icon(Icons.fingerprint_rounded, size: 26),
              label: const Text(
                'Sign Up with Fingerprint',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Login Form: Email / PIN login + "Login with Fingerprint"
  Widget _buildLoginForm(KhaataProvider provider, AppLocalizations l10n) {
    final user = provider.currentUser;
    final userName = user?.name.isNotEmpty == true ? user!.name : provider.userName;
    final userEmail = user?.email.isNotEmpty == true ? user!.email : provider.userEmail;
    final imagePath = user?.imagePath ?? provider.userImagePath;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.translate('login'),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3C72),
              ),
            ),
            TextButton.icon(
              onPressed: () {
                setState(() => _isSignUpMode = true);
              },
              icon: const Icon(Icons.person_add_rounded, size: 16),
              label: const Text('New Account', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const Divider(height: 20),
        const SizedBox(height: 10),

        // User Avatar from SQLite
        CircleAvatar(
          radius: 42,
          backgroundColor: const Color(0xFF1E3C72).withAlpha(25),
          backgroundImage: imagePath != null && imagePath.isNotEmpty && !kIsWeb && File(imagePath).existsSync()
              ? FileImage(File(imagePath))
              : null,
          child: (imagePath == null || imagePath.isEmpty || kIsWeb || !File(imagePath).existsSync())
              ? Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF1E3C72)),
                )
              : null,
        ),
        const SizedBox(height: 10),

        Text(
          userName.isNotEmpty ? userName : 'User',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E3C72)),
        ),
        if (userEmail.isNotEmpty)
          Text(
            userEmail,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        const SizedBox(height: 20),

        // Login PIN Field
        TextFormField(
          controller: _loginPinController,
          keyboardType: TextInputType.number,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Enter Security PIN *',
            hintText: 'e.g. 1234',
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 20),

        // Button 1: "Login" (PIN)
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3C72),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 3,
            ),
            onPressed: _isProcessing ? null : _submitLogin,
            child: const Text(
              'Login to Khaata',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Button 2: "Login with Fingerprint"
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1E3C72),
              side: const BorderSide(color: Color(0xFF1E3C72), width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: _isProcessing ? null : _loginWithFingerprint,
            icon: const Icon(Icons.fingerprint_rounded, size: 26),
            label: const Text(
              'Login with Fingerprint',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
