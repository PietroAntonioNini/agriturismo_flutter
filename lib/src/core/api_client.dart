import 'dart:convert';
import 'package:http/http.dart' as http;

/// Client API per comunicazione con backend FastAPI
/// Gestisce autenticazione JWT, headers e parsing response
class ApiClient {
  final String baseUrl;
  String? _accessToken;
  String? _csrfToken;
  int? _userId;

  ApiClient(this.baseUrl);

  /// Imposta il token JWT per le richieste autenticate
  void setAccessToken(String? token) {
    _accessToken = token;
  }

  /// Imposta il CSRF token per operazioni di modifica (POST/PUT/DELETE)
  void setCsrfToken(String? token) {
    _csrfToken = token;
  }

  /// Imposta l'ID utente corrente (obbligatorio per query API)
  void setUserId(int? userId) {
    _userId = userId;
  }

  /// Headers comuni per richieste HTTP
  Map<String, String> _headers({bool json = true, bool needsCsrf = false}) {
    final headers = <String, String>{};
    if (json) headers['Content-Type'] = 'application/json';
    if (_accessToken != null) headers['Authorization'] = 'Bearer $_accessToken!';
    if (needsCsrf && _csrfToken != null) headers['X-CSRF-Token'] = _csrfToken!;
    return headers;
  }

  /// Login con username e password
  /// Returns: {accessToken, refreshToken, tokenType, expiresIn}
  /// NOTA: NON restituisce l'user ID! Usa verifyToken() dopo il login per ottenerlo
  Future<Map<String, dynamic>> login(String username, String password) async {
    final url = Uri.parse('$baseUrl/api/auth/login');
    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'username': username, 'password': password},
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Login failed: ${res.statusCode} ${res.body}');
  }

  /// Verifica il token e recupera il profilo utente completo (con user ID)
  /// Questo è l'endpoint primario per ottenere l'user ID dopo il login
  Future<Map<String, dynamic>> verifyToken() async {
    final url = Uri.parse('$baseUrl/api/auth/verify-token');
    final res = await http.get(url, headers: _headers());

    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Verify token failed: ${res.statusCode} ${res.body}');
  }

  /// Recupera il profilo utente (fallback per verify-token)
  /// Restituisce: {id, username, email, firstName, lastName, role, isActive, ...}
  Future<Map<String, dynamic>> getUserProfile() async {
    final url = Uri.parse('$baseUrl/api/users/me');
    final res = await http.get(url, headers: _headers());

    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Get user profile failed: ${res.statusCode} ${res.body}');
  }

  /// Ottiene lista appartamenti
  /// IMPORTANTE: Richiede user_id come query parameter
  Future<List<dynamic>> getApartments() async {
    if (_userId == null) {
      throw Exception('User ID is required. Call setUserId() after login.');
    }
    
    // URL con trailing slash + query parameter user_id
    final url = Uri.parse('$baseUrl/apartments/').replace(
      queryParameters: {'user_id': _userId.toString()},
    );
    final res = await http.get(url, headers: _headers());

    if (res.statusCode == 200) {
      return jsonDecode(res.body) as List<dynamic>;
    }
    throw Exception('Get apartments failed: ${res.statusCode} - ${res.body}');
  }

  /// Ottiene tipi di utility disponibili (electricity, water, gas)
  Future<List<dynamic>> getUtilityTypes() async {
    final url = Uri.parse('$baseUrl/utilities/types');
    final res = await http.get(url, headers: _headers());

    if (res.statusCode == 200) {
      return jsonDecode(res.body) as List<dynamic>;
    }
    throw Exception('Get types failed: ${res.statusCode}');
  }

  /// Ottiene ultima lettura per appartamento e tipo utility
  /// Returns: {hasHistory, lastReading, lastReadingDate, apartmentId, type}
  /// Se 404 (nessuna storia) ritorna valori di default con hasHistory=false
  Future<Map<String, dynamic>> getLastReading(
    int apartmentId,
    String type, {
    String? subtype,
  }) async {
    var urlString = '$baseUrl/utilities/last-reading/$apartmentId/$type';
    if (subtype != null) {
      urlString += '?subtype=$subtype';
    }
    final url = Uri.parse(urlString);
    final res = await http.get(url, headers: _headers());

    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }

    // 404 = nessuna storia precedente, ritorna default
    if (res.statusCode == 404) {
      return {
        'hasHistory': false,
        'lastReading': 0,
        'lastReadingDate': null,
        'apartmentId': apartmentId,
        'type': type,
        if (subtype != null) 'subtype': subtype,
      };
    }

    throw Exception('Get last reading failed: ${res.statusCode}');
  }

  /// Crea una nuova lettura utility
  /// Returns: la lettura creata con id e timestamp
  /// IMPORTANTE: Richiede CSRF token e user_id
  Future<Map<String, dynamic>> createReading(
    Map<String, dynamic> payload,
  ) async {
    if (_userId == null) {
      throw Exception('User ID is required. Call setUserId() after login.');
    }
    
    // URL con trailing slash + query parameter user_id
    final url = Uri.parse('$baseUrl/utilities/').replace(
      queryParameters: {'user_id': _userId.toString()},
    );
    
    // Headers con CSRF token (necessario per POST)
    final res = await http.post(
      url,
      headers: _headers(needsCsrf: true),
      body: jsonEncode(payload),
    );

    if (res.statusCode == 201 || res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }

    // Parsing errore dettagliato dal backend
    String errorMessage = 'Create reading failed: ${res.statusCode}';
    try {
      final errorBody = jsonDecode(res.body);
      if (errorBody['detail'] != null) {
        errorMessage = errorBody['detail'].toString();
      }
    } catch (_) {
      errorMessage += ' - ${res.body}';
    }

    throw Exception(errorMessage);
  }

  /// Ottiene il CSRF token dal server (da chiamare dopo login)
  Future<String> getCsrfToken() async {
    final url = Uri.parse('$baseUrl/api/auth/csrf-token');
    final res = await http.get(url, headers: _headers());

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return data['csrf_token'] as String;
    }
    throw Exception('Get CSRF token failed: ${res.statusCode} - ${res.body}');
  }
}
