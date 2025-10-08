import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';

/// Servizio di autenticazione che replica esattamente il flusso del frontend Angular
/// Segue il documento s.md: Login → Token → Verify → User Profile → CSRF → Ready
class AuthService {
  final String baseUrl;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  String? _accessToken;
  String? _refreshToken;
  String? _csrfToken;
  User? _currentUser;

  AuthService(this.baseUrl);

  /// Login completo seguendo il flusso Angular:
  /// 1. POST /api/auth/login → ottieni token
  /// 2. Salva token nel secure storage
  /// 3. GET /api/auth/verify-token → ottieni profilo utente (con ID)
  /// 4. Fallback GET /api/users/me se verify-token non ha ID
  /// 5. Salva user completo nel storage
  /// 6. GET /api/auth/csrf-token → ottieni CSRF token
  /// 7. Salva CSRF token
  Future<User> login(String username, String password) async {
    // Step 1: Login per ottenere i token
    final loginResponse = await _performLogin(username, password);
    
    // Step 2: Salva i token
    await _storeTokens(loginResponse);
    
    // Step 3: Recupera il profilo utente (con user ID)
    final user = await _loadUserProfile(loginResponse['accessToken']);
    
    // Step 4: Salva l'utente completo
    await _storage.write(key: 'current_user', value: jsonEncode(user.toJson()));
    _currentUser = user;
    
    // Step 5: Recupera CSRF token
    await _getCsrfToken(loginResponse['accessToken']);
    
    return user;
  }

  /// Step 1: Chiamata di login
  Future<Map<String, dynamic>> _performLogin(String username, String password) async {
    final uri = Uri.parse('$baseUrl/api/auth/login');
    
    // Crea FormData (x-www-form-urlencoded)
    final request = http.MultipartRequest('POST', uri);
    request.fields['username'] = username;
    request.fields['password'] = password;
    
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    if (response.statusCode != 200) {
      throw Exception('Login failed: ${response.body}');
    }
    
    return jsonDecode(response.body);
  }

  /// Step 2: Salva i token nel secure storage
  Future<void> _storeTokens(Map<String, dynamic> loginResponse) async {
    final accessToken = loginResponse['accessToken'];
    final refreshToken = loginResponse['refreshToken'];
    final expiresIn = loginResponse['expiresIn'];
    
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    
    await _storage.write(key: 'access_token', value: accessToken);
    await _storage.write(key: 'refresh_token', value: refreshToken);
    
    // Calcola expires_at
    final expiresAt = DateTime.now().millisecondsSinceEpoch + (expiresIn * 1000);
    await _storage.write(key: 'expires_at', value: expiresAt.toString());
  }

  /// Step 3: Recupera il profilo utente
  Future<User> _loadUserProfile(String accessToken) async {
    // Tentativo 1: /api/auth/verify-token
    try {
      final uri = Uri.parse('$baseUrl/api/auth/verify-token');
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $accessToken'},
      );
      
      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        
        // Verifica se contiene l'id
        if (userData['id'] != null) {
          return User.fromJson(userData);
        }
        
        // Se non ha id, prova il fallback
        return await _loadUserProfileFallback(accessToken);
      }
    } catch (e) {
      print('Error with verify-token, trying /users/me: $e');
    }
    
    // Tentativo 2 (fallback): /api/users/me
    return await _loadUserProfileFallback(accessToken);
  }

  /// Fallback: Usa /api/users/me
  Future<User> _loadUserProfileFallback(String accessToken) async {
    final uri = Uri.parse('$baseUrl/api/users/me');
    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to load user profile: ${response.body}');
    }
    
    final userData = jsonDecode(response.body);
    return User.fromJson(userData);
  }

  /// Step 5: Recupera CSRF token
  Future<void> _getCsrfToken(String accessToken) async {
    try {
      final uri = Uri.parse('$baseUrl/api/auth/csrf-token');
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $accessToken'},
      );
      
      if (response.statusCode == 200) {
        final csrfData = jsonDecode(response.body);
        _csrfToken = csrfData['csrf_token'];
        await _storage.write(key: 'csrf_token', value: _csrfToken!);
      }
    } catch (e) {
      print('Error getting CSRF token: $e');
    }
  }

  /// Carica lo stato dell'autenticazione dal storage
  Future<void> loadStoredAuth() async {
    _accessToken = await _storage.read(key: 'access_token');
    _refreshToken = await _storage.read(key: 'refresh_token');
    _csrfToken = await _storage.read(key: 'csrf_token');
    
    final userJson = await _storage.read(key: 'current_user');
    if (userJson != null) {
      try {
        _currentUser = User.fromJson(jsonDecode(userJson));
      } catch (e) {
        print('Error parsing stored user: $e');
      }
    }
  }

  /// Verifica se l'utente è loggato e il token non è scaduto
  Future<bool> isLoggedIn() async {
    if (_accessToken == null) return false;
    
    final expiresAtStr = await _storage.read(key: 'expires_at');
    if (expiresAtStr == null) return false;
    
    final expiresAt = int.parse(expiresAtStr);
    return DateTime.now().millisecondsSinceEpoch < expiresAt;
  }

  /// Recupera l'user ID salvato
  int? getUserId() => _currentUser?.id;

  /// Recupera l'utente completo
  User? getCurrentUser() => _currentUser;

  /// Recupera l'access token
  String? getAccessToken() => _accessToken;

  /// Recupera il CSRF token
  String? getCsrfToken() => _csrfToken;

  /// Logout
  Future<void> logout() async {
    _accessToken = null;
    _refreshToken = null;
    _csrfToken = null;
    _currentUser = null;
    await _storage.deleteAll();
  }

  /// Headers per richieste autenticate
  Map<String, String> getAuthHeaders({bool needsCsrf = false}) {
    final headers = <String, String>{};
    
    if (_accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken!';
    }
    
    if (needsCsrf && _csrfToken != null) {
      headers['X-CSRF-Token'] = _csrfToken!;
    }
    
    return headers;
  }
}