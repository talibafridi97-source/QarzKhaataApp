import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/khaata_provider.dart';

/// Screen for User Onboarding, Sign Up, Login, Biometric Unlock, and Multi-Language support.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _pinController = TextEditingController();

  bool _isSignUpMode = true;
  String _livePreviewName = '';

  @override
  void initState() {
    super.initState();
    final provider = context.read<KhaataProvider>();
    if (provider.hasAccount) {
      _isSignUpMode = false;
      _nameController.text = provider.userName;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<KhaataProvider>();

    if (_isSignUpMode) {
      final success = await provider.signUp(
        name: _nameController.text,
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

  void _tryBiometric() async {
    final provider = context.read<KhaataProvider>();
    final success = await provider.authenticateWithBiometrics();
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Biometric authentication successful!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<KhaataProvider>();
    final hasAccount = provider.hasAccount;
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
                                // Header Switch
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
                                    if (hasAccount)
                                      TextButton(
                                        onPressed: () {
                                          setState(() {
                                            _isSignUpMode = !_isSignUpMode;
                                            _pinController.clear();
                                          });
                                        },
                                        child: Text(
                                          _isSignUpMode ? l10n.translate('login') : l10n.translate('signup'),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.indigo,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const Divider(height: 24),

                                // Sign Up Name Field
                                if (_isSignUpMode) ...[
                                  TextFormField(
                                    controller: _nameController,
                                    textCapitalization: TextCapitalization.words,
                                    decoration: InputDecoration(
                                      labelText: 'Your Name / Business Owner *',
                                      hintText: 'e.g. Talibjan',
                                      prefixIcon: const Icon(Icons.person_rounded),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onChanged: (val) {
                                      setState(() {
                                        _livePreviewName = val.trim();
                                      });
                                    },
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) {
                                        return 'Please enter your name';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),

                                  // Live Preview Box
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.indigo.withAlpha(15),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.indigo.withAlpha(40),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.storefront_rounded,
                                          color: Colors.indigo,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Header Title Preview:',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              Text(
                                                _livePreviewName.isEmpty
                                                    ? 'Talibjan Khaata'
                                                    : (_livePreviewName
                                                            .toLowerCase()
                                                            .endsWith('khaata')
                                                        ? _livePreviewName
                                                        : '$_livePreviewName Khaata'),
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.indigo,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
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
                                ),
                                const SizedBox(height: 24),

                                // Action Button
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

                                // Biometric Fingerprint Button (if account exists and in login mode)
                                if (hasAccount && !_isSignUpMode) ...[
                                  const SizedBox(height: 16),
                                  Center(
                                    child: TextButton.icon(
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.indigo,
                                      ),
                                      onPressed: _tryBiometric,
                                      icon: const Icon(Icons.fingerprint_rounded, size: 28),
                                      label: const Text(
                                        'Unlock with Fingerprint / Biometrics',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ],
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
