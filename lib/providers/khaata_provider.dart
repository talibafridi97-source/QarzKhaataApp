import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import '../models/debtor_model.dart';
import '../models/transaction_model.dart';
import '../models/user_model.dart';
import '../services/biometric_service.dart';
import '../services/secure_storage_service.dart';

/// Provider class handling state management for auth, localization, biometrics, and ledger.
class KhaataProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  static const String _prefIsLoggedInKey = 'is_logged_in';
  static const String _prefUserNameKey = 'user_name';
  static const String _prefUserEmailKey = 'user_email';
  static const String _prefUserPinKey = 'user_pin';
  static const String _prefBusinessNameKey = 'business_name';
  static const String _prefLocaleKey = 'app_locale';

  bool _isLoggedIn = false;
  String _userName = '';
  String _userEmail = '';
  String _userPin = '';
  String _businessName = 'My Business Khata';
  String _locale = 'en'; // 'en', 'ur', 'ps', 'ar'
  bool _isBiometricEnabled = false;
  bool _hasLocalUser = false;
  UserModel? _currentUser;

  String _searchQuery = '';
  bool _isLoading = false;

  List<Debtor> _debtors = [];
  List<Debtor> _filteredDebtors = [];

  Debtor? _currentDebtor;
  List<TransactionModel> _currentDebtorTransactions = [];

  // Getters
  bool get isLoggedIn => _isLoggedIn;
  String get userName => _userName;
  String get userEmail => _userEmail;
  String get userPin => _userPin;
  bool get hasAccount => _hasLocalUser || _userName.isNotEmpty;
  bool get hasLocalUser => _hasLocalUser;
  bool get isBiometricEnabled => _isBiometricEnabled;
  UserModel? get currentUser => _currentUser;
  String? get userImagePath => _currentUser?.imagePath;
  String get locale => _locale;

  String get businessName => _businessName;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  List<Debtor> get debtors => _debtors;
  List<Debtor> get filteredDebtors => _filteredDebtors;
  Debtor? get currentDebtor => _currentDebtor;
  List<TransactionModel> get currentDebtorTransactions => _currentDebtorTransactions;

  /// Calculate total amount to collect (sum of positive running balances)
  double get totalReceivable {
    return _debtors
        .where((d) => d.netBalance > 0)
        .fold(0.0, (sum, d) => sum + d.netBalance);
  }

  /// Calculate total amount to give back (sum of negative running balances)
  double get totalPayable {
    return _debtors
        .where((d) => d.netBalance < 0)
        .fold(0.0, (sum, d) => sum + d.netBalance.abs());
  }

  /// Initialize provider state
  Future<void> init() async {
    _setLoading(true);
    await _loadAuthAndProfile();
    await loadDebtors();
    _setLoading(false);
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Load Auth, Locale & Profile settings from SQLite, SecureStorage, and SharedPreferences
  Future<void> _loadAuthAndProfile() async {
    try {
      // 1. Fetch user from SQLite database
      _currentUser = await _dbHelper.getUser();
      if (_currentUser != null) {
        _hasLocalUser = true;
        _userName = _currentUser!.name;
        _userEmail = _currentUser!.email;
        _businessName = '${_currentUser!.name} Khaata';
      }

      // 2. Fetch biometric flag from SecureStorage
      _isBiometricEnabled = await SecureStorageService.instance.isBiometricEnabled();

      // 3. SharedPreferences settings
      final prefs = await SharedPreferences.getInstance();
      _isLoggedIn = prefs.getBool(_prefIsLoggedInKey) ?? false;
      if (_userName.isEmpty) {
        _userName = prefs.getString(_prefUserNameKey) ?? '';
        _userEmail = prefs.getString(_prefUserEmailKey) ?? '';
      }
      _userPin = prefs.getString(_prefUserPinKey) ?? '';
      _businessName = prefs.getString(_prefBusinessNameKey) ??
          (_userName.isNotEmpty ? '$_userName Khaata' : 'My Business Khata');
      _locale = prefs.getString(_prefLocaleKey) ?? 'en';
    } catch (e) {
      debugPrint('Error loading auth/profile: $e');
    }
  }

  /// Set and persist application language locale ('en', 'ur', 'ps', 'ar')
  Future<void> setLocale(String newLocale) async {
    if (_locale == newLocale) return;
    _locale = newLocale;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefLocaleKey, _locale);
    } catch (e) {
      debugPrint('Error saving locale: $e');
    }
  }

  /// Sign Up with Fingerprint / Biometric
  Future<BiometricResult> signUpWithBiometrics({
    required String name,
    required String email,
    String? imagePath,
  }) async {
    final trimmedName = name.trim();
    final trimmedEmail = email.trim();

    if (trimmedName.isEmpty || trimmedEmail.isEmpty) {
      return BiometricResult.failure('Name and Email are required.');
    }

    // 1. Trigger biometric prompt
    final bioResult = await BiometricService.instance.authenticate(
      localizedReason: 'Scan your fingerprint to register and secure your account',
    );

    if (!bioResult.success) {
      return bioResult;
    }

    try {
      // 2. Save user to SQLite
      final user = UserModel(
        name: trimmedName,
        email: trimmedEmail,
        imagePath: imagePath,
        createdAt: DateTime.now(),
      );
      await _dbHelper.insertUser(user);
      _currentUser = await _dbHelper.getUser() ?? user;

      // 3. Save flag in flutter_secure_storage
      await SecureStorageService.instance.setBiometricEnabled(true);
      await SecureStorageService.instance.saveUserEmail(trimmedEmail);

      // 4. Update in-memory state & SharedPreferences
      _userName = trimmedName;
      _userEmail = trimmedEmail;
      _businessName = '$trimmedName Khaata';
      _isBiometricEnabled = true;
      _hasLocalUser = true;
      _isLoggedIn = true;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefUserNameKey, _userName);
      await prefs.setString(_prefUserEmailKey, _userEmail);
      await prefs.setString(_prefBusinessNameKey, _businessName);
      await prefs.setBool(_prefIsLoggedInKey, true);

      notifyListeners();
      return BiometricResult.success();
    } catch (e) {
      debugPrint('Error during biometric signup: $e');
      return BiometricResult.failure('Failed to save account details: $e');
    }
  }

  /// Login with Fingerprint / Biometric
  Future<BiometricResult> loginWithBiometrics() async {
    try {
      final user = await _dbHelper.getUser();
      if (user == null) {
        return BiometricResult.failure('No registered account found. Please sign up first.');
      }

      final isBioEnabled = await SecureStorageService.instance.isBiometricEnabled();
      if (!isBioEnabled) {
        return BiometricResult.failure('Biometric login is not enabled for this device.');
      }

      final bioResult = await BiometricService.instance.authenticate(
        localizedReason: 'Scan your fingerprint to log into ${user.name}\'s Khaata',
      );

      if (!bioResult.success) {
        return bioResult;
      }

      _currentUser = user;
      _userName = user.name;
      _userEmail = user.email;
      _businessName = '${user.name} Khaata';
      _isBiometricEnabled = true;
      _hasLocalUser = true;
      _isLoggedIn = true;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefIsLoggedInKey, true);

      notifyListeners();
      return BiometricResult.success();
    } catch (e) {
      debugPrint('Error during biometric login: $e');
      return BiometricResult.failure('Login failed: $e');
    }
  }

  /// Sign Up with PIN
  Future<bool> signUpWithPin({
    required String name,
    required String email,
    required String pin,
    String? profilePicPath,
  }) async {
    final trimmedName = name.trim();
    final trimmedEmail = email.trim();
    final trimmedPin = pin.trim();

    if (trimmedName.isEmpty || trimmedEmail.isEmpty || trimmedPin.isEmpty) {
      return false;
    }

    try {
      final user = UserModel(
        name: trimmedName,
        email: trimmedEmail,
        imagePath: profilePicPath,
        createdAt: DateTime.now(),
      );
      await _dbHelper.insertUser(user);
      _currentUser = user;
      _userName = trimmedName;
      _userEmail = trimmedEmail;
      _userPin = trimmedPin;
      _businessName = '$trimmedName Khaata';
      _hasLocalUser = true;
      _isLoggedIn = true;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefUserNameKey, _userName);
      await prefs.setString(_prefUserEmailKey, _userEmail);
      await prefs.setString(_prefUserPinKey, _userPin);
      await prefs.setString(_prefBusinessNameKey, _businessName);
      await prefs.setBool(_prefIsLoggedInKey, true);

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error signing up with PIN: $e');
      return false;
    }
  }

  /// Sign Up with Fingerprint
  Future<bool> signUpWithFingerprint({
    required String name,
    required String email,
    required String pin,
    String? profilePicPath,
  }) async {
    final result = await signUpWithBiometrics(
      name: name,
      email: email,
      imagePath: profilePicPath,
    );
    if (result.success) {
      _userPin = pin.trim();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefUserPinKey, _userPin);
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Login with PIN
  Future<bool> loginWithPin(String pin) async {
    try {
      final user = await _dbHelper.getUser();
      if (user != null && (_userPin.isEmpty || pin.trim() == _userPin)) {
        _currentUser = user;
        _userName = user.name;
        _userEmail = user.email;
        _businessName = '${user.name} Khaata';
        _hasLocalUser = true;
        _isLoggedIn = true;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_prefIsLoggedInKey, true);

        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error logging in with PIN: $e');
    }
    return false;
  }

  /// Login with Fingerprint
  Future<UserModel?> loginWithFingerprint() async {
    final result = await loginWithBiometrics();
    if (result.success) {
      return _currentUser;
    }
    return null;
  }

  /// Sign Up a new user with name, email, pin and automatically set Business Title as "[Name] Khaata"
  Future<bool> signUp({required String name, required String email, required String pin}) async {
    return await signUpWithPin(name: name, email: email, pin: pin);
  }

  /// Login existing user
  Future<bool> login(String pin) async {
    return await loginWithPin(pin);
  }

  /// Log out current user
  Future<void> logout() async {
    _isLoggedIn = false;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefIsLoggedInKey, false);
    } catch (e) {
      debugPrint('Error logging out: $e');
    }
  }

  /// Update Business/Profile name
  Future<void> setBusinessName(String name) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return;

    _businessName = trimmedName;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefBusinessNameKey, _businessName);
    } catch (e) {
      debugPrint('Error saving business name: $e');
    }
  }

  /// Load all debtors with computed balances from SQLite
  Future<void> loadDebtors() async {
    try {
      _debtors = await _dbHelper.getDebtorsWithBalances();
      _applySearchFilter();
    } catch (e) {
      debugPrint('Error loading debtors: $e');
    }
    notifyListeners();
  }

  /// Set search query and update filtered list in real-time
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applySearchFilter();
    notifyListeners();
  }

  /// Apply real-time search filtering on debtors list
  void _applySearchFilter() {
    if (_searchQuery.trim().isEmpty) {
      _filteredDebtors = List.from(_debtors);
    } else {
      final query = _searchQuery.toLowerCase().trim();
      _filteredDebtors = _debtors.where((debtor) {
        final nameMatch = debtor.name.toLowerCase().contains(query);
        final phoneMatch = debtor.phone.contains(query);
        return nameMatch || phoneMatch;
      }).toList();
    }
  }

  /// Add a new debtor (Kharzdaar)
  Future<bool> addDebtor(String name, String phone) async {
    try {
      final newDebtor = Debtor(
        name: name.trim(),
        phone: phone.trim(),
        createdAt: DateTime.now(),
      );
      final id = await _dbHelper.insertDebtor(newDebtor);
      if (id > 0) {
        _searchQuery = '';
        await loadDebtors();
        return true;
      }
    } catch (e, stack) {
      debugPrint('Error adding debtor: $e\n$stack');
    }
    return false;
  }

  /// Update debtor information
  Future<bool> updateDebtor(Debtor debtor) async {
    try {
      final count = await _dbHelper.updateDebtor(debtor);
      if (count > 0) {
        await loadDebtors();
        if (_currentDebtor?.id == debtor.id) {
          _currentDebtor = await _dbHelper.getDebtorById(debtor.id!);
        }
        return true;
      }
    } catch (e) {
      debugPrint('Error updating debtor: $e');
    }
    return false;
  }

  /// Delete a debtor and all their transactions
  Future<bool> deleteDebtor(int debtorId) async {
    try {
      final count = await _dbHelper.deleteDebtor(debtorId);
      if (count > 0) {
        if (_currentDebtor?.id == debtorId) {
          _currentDebtor = null;
          _currentDebtorTransactions = [];
        }
        await loadDebtors();
        return true;
      }
    } catch (e) {
      debugPrint('Error deleting debtor: $e');
    }
    return false;
  }

  /// Load detail view for a debtor and their transaction history
  Future<void> loadDebtorDetail(int debtorId) async {
    _setLoading(true);
    try {
      _currentDebtor = await _dbHelper.getDebtorById(debtorId);
      _currentDebtorTransactions = await _dbHelper.getTransactionsForDebtor(debtorId);
    } catch (e) {
      debugPrint('Error loading debtor detail: $e');
    }
    _setLoading(false);
  }

  /// Add a ledger transaction for current debtor
  Future<bool> addTransaction(TransactionModel transaction) async {
    try {
      final id = await _dbHelper.insertTransaction(transaction);
      if (id > 0) {
        await loadDebtorDetail(transaction.debtorId);
        await loadDebtors();
        return true;
      }
    } catch (e) {
      debugPrint('Error adding transaction: $e');
    }
    return false;
  }

  /// Update an existing transaction record
  Future<bool> updateTransaction(TransactionModel transaction) async {
    try {
      final count = await _dbHelper.updateTransaction(transaction);
      if (count > 0) {
        await loadDebtorDetail(transaction.debtorId);
        await loadDebtors();
        return true;
      }
    } catch (e) {
      debugPrint('Error updating transaction: $e');
    }
    return false;
  }

  /// Delete a transaction
  Future<bool> deleteTransaction(int transactionId, int debtorId) async {
    try {
      final count = await _dbHelper.deleteTransaction(transactionId);
      if (count > 0) {
        await loadDebtorDetail(debtorId);
        await loadDebtors();
        return true;
      }
    } catch (e) {
      debugPrint('Error deleting transaction: $e');
    }
    return false;
  }
}
