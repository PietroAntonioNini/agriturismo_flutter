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

  /// Costruisce URI con user_id automatico per le risorse che lo richiedono
  Uri _buildResourceUri(String path, {Map<String, String>? queryParams}) {
    final params = queryParams ?? <String, String>{};
    
    // Aggiungi user_id se necessario e disponibile
    final userId = _authService.getUserId();
    if (userId != null && _requiresUserId(path)) {
      params['user_id'] = userId.toString();
    }
    
    return Uri.parse('$baseUrl$path').replace(queryParameters: params);
  }

  /// Verifica se l'endpoint richiede user_id
  bool _requiresUserId(String path) {
    return path.contains('/apartments') ||
           path.contains('/tenants') ||
           path.contains('/leases') ||
           path.contains('/invoices') ||
           path.contains('/utilities');
  }

  /// Ottiene lista appartamenti
  /// IMPORTANTE: Richiede user_id come query parameter (aggiunto automaticamente)
  Future<List<dynamic>> getApartments() async {
    final userId = _authService.getUserId();
    if (userId == null) {
      throw Exception('User not logged in or user ID not available');
    }
    
    // URL con trailing slash + query parameter user_id (automatico)
    final url = _buildResourceUri('/apartments/');
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
  /// IMPORTANTE: Richiede CSRF token e user_id (aggiunti automaticamente)
  Future<Map<String, dynamic>> createReading(
    Map<String, dynamic> payload,
  ) async {
    final userId = _authService.getUserId();
    if (userId == null) {
      throw Exception('User not logged in or user ID not available');
    }
    
    // URL con trailing slash + query parameter user_id (automatico)
    final url = _buildResourceUri('/utilities/');
    
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
