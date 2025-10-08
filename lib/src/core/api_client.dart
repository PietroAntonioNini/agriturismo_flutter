import 'dart:convert';
import 'package:http/http.dart' as http;

/// Client API per comunicazione con backend FastAPI
/// Gestisce autenticazione JWT, headers e parsing response
class ApiClient {
  final String baseUrl;
  String? _accessToken;

  ApiClient(this.baseUrl);

  /// Imposta il token JWT per le richieste autenticate
  void setAccessToken(String? token) {
    _accessToken = token;
  }

  /// Headers comuni per richieste HTTP
  Map<String, String> _headers({bool json = true}) => {
    if (json) 'Content-Type': 'application/json',
    if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
  };

  /// Login con username e password
  /// Returns: {accessToken, refreshToken, tokenType, expiresIn}
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

  /// Ottiene lista appartamenti
  Future<List<dynamic>> getApartments() async {
    final url = Uri.parse('$baseUrl/apartments');
    final res = await http.get(url, headers: _headers());

    if (res.statusCode == 200) {
      return jsonDecode(res.body) as List<dynamic>;
    }
    throw Exception('Get apartments failed: ${res.statusCode}');
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
  Future<Map<String, dynamic>> createReading(
    Map<String, dynamic> payload,
  ) async {
    final url = Uri.parse('$baseUrl/utilities');
    final res = await http.post(
      url,
      headers: _headers(),
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
}
