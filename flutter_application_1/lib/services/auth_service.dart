import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preview identity only; no server account or authenticated session is created.
class AuthService extends ChangeNotifier {
  AuthService._();
  static final instance = AuthService._();
  String displayName = 'Хэрэглэгч';
  String email = '', phone = '';
  String? _identifier;
  Future<void> register(String name, String identifier, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 650));
    displayName = name.trim();
    _identifier = identifier.trim();
    await _loadProfile();
    notifyListeners();
  }

  Future<void> login(String identifier, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (_identifier != identifier.trim()) displayName = 'Хэрэглэгч';
    _identifier = identifier.trim();
    await _loadProfile();
    notifyListeners();
  }

  String get _key =>
      'sanaa.profile.${Uri.encodeComponent(_identifier ?? 'local')}';
  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    displayName = prefs.getString('$_key.name') ?? displayName;
    email =
        prefs.getString('$_key.email') ??
        ((_identifier ?? '').contains('@') ? _identifier! : '');
    phone =
        prefs.getString('$_key.phone') ??
        (RegExp(r'^\+?[0-9]{8,15}$').hasMatch(_identifier ?? '')
            ? _identifier!
            : '');
  }

  Future<void> loadProfile() async {
    await _loadProfile();
    notifyListeners();
  }

  Future<void> updateProfile(
    String name,
    String newEmail,
    String newPhone,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString('$_key.name', name) ||
        !await prefs.setString('$_key.email', newEmail) ||
        !await prefs.setString('$_key.phone', newPhone)) {
      throw StateError('storage');
    }
    displayName = name;
    email = newEmail;
    phone = newPhone;
    notifyListeners();
  }
}
