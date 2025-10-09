import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

/// Client API per comunicazione con backend FastAPI
/// Integrato con AuthService per gestione completa dell'autenticazione
class ApiClient {
  final String baseUrl;
  final AuthService _authService;

  ApiClient(this.baseUrl, this._authService);

  /// Headers comuni per richieste HTTP
  Map<String, String> _headers({bool json = true, bool needsCsrf = false}) {
    final headers = <String, String>{};
    if (json) headers['Content-Type'] = 'application/json';
    
    // Usa AuthService per ottenere gli header di autenticazione
    final authHeaders = _authService.getAuthHeaders(needsCsrf: needsCsrf);
    headers.addAll(authHeaders);
    
    return headers;
  }

  /// Ottiene lista appartamenti
  /// Il backend estrae automaticamente user_id dal token JWT
  Future<List<dynamic>> getApartments() async {
    final url = Uri.parse('$baseUrl/apartments/');
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
  /// Il backend estrae automaticamente user_id dal token JWT
  /// IMPORTANTE: Richiede CSRF token per POST
  Future<Map<String, dynamic>> createReading(
    Map<String, dynamic> payload,
  ) async {
    final url = Uri.parse('$baseUrl/utilities/');
    
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
}
