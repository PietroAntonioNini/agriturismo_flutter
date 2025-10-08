import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';

/// Base URL backend su Koyeb
const baseUrl = 'https://flat-damselfly-agriturismo-backend-47075869.koyeb.app';

/// Provider singleton per ApiClient
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient(baseUrl));

// ============================================================================
// AUTH PROVIDERS
// ============================================================================

/// Stato autenticazione con access token
class AuthState {
  final String? accessToken;
  const AuthState(this.accessToken);

  bool get isAuthenticated => accessToken != null;
}

/// Notifier per gestione autenticazione
class AuthNotifier extends Notifier<AuthState> {
  late final ApiClient _client;

  @override
  AuthState build() {
    _client = ref.read(apiClientProvider);
    return const AuthState(null);
  }

  /// Effettua login e recupera user profile
  /// Segue il flusso del frontend Angular con fallback robusto:
  /// 1. Login con username/password → ottieni token
  /// 2. Salva access token
  /// 3. TENTA di recuperare user profile (può fallire se endpoint non esiste)
  /// 4. Se tutti i tentativi falliscono, usa userId = 1 come fallback temporaneo
  /// 5. Richiedi CSRF token (necessario per POST/PUT/DELETE)
  Future<void> login(String username, String password) async {
    // Step 1: Login per ottenere i token
    final data = await _client.login(username, password);
    final token = data['accessToken'] as String;
    _client.setAccessToken(token);
    
    // Step 2: TENTA di recuperare il profilo utente (con user ID)
    int? userId;
    
    // Tentativo 1: /api/auth/verify-token
    try {
      final userProfile = await _client.verifyToken();
      if (userProfile['id'] != null) {
        userId = userProfile['id'] as int;
        print('✅ User profile loaded from verify-token. User ID: $userId');
      }
    } catch (e) {
      print('⚠️ verify-token failed: $e');
    }
    
    // Tentativo 2: /api/users/me (se il primo fallisce o non ha id)
    if (userId == null) {
      try {
        final userProfile = await _client.getUserProfile();
        if (userProfile['id'] != null) {
          userId = userProfile['id'] as int;
          print('✅ User profile loaded from /users/me. User ID: $userId');
        }
      } catch (e) {
        print('⚠️ getUserProfile failed: $e');
      }
    }
    
    // Tentativo 3: Controlla se il login ha restituito user info
    if (userId == null && data['user'] != null) {
      final user = data['user'] as Map<String, dynamic>;
      if (user['id'] != null) {
        userId = user['id'] as int;
        print('✅ User ID extracted from login response: $userId');
      }
    }
    
    // Fallback finale: Se TUTTI i tentativi falliscono, usa un valore di default
    // NOTA: Questo è temporaneo finché non scopriamo l'endpoint corretto
    if (userId == null) {
      print('⚠️ WARNING: Could not retrieve user ID from any endpoint!');
      print('💡 Using fallback user ID = 1');
      userId = 1; // Assumiamo che l'utente loggato sia id=1
    }
    
    _client.setUserId(userId);
    
    // Step 3: Ottieni CSRF token (necessario per operazioni POST/PUT/DELETE)
    try {
      final csrfToken = await _client.getCsrfToken();
      _client.setCsrfToken(csrfToken);
      print('✅ CSRF token obtained successfully');
    } catch (e) {
      // CSRF token fetch fallito, ma continua comunque
      print('⚠️ Warning: Could not fetch CSRF token: $e');
    }
    
    state = AuthState(token);
    print('🎉 Login completed successfully!');
  }

  /// Logout (pulizia stato locale)
  void logout() {
    _client.setAccessToken(null);
    _client.setUserId(null);
    _client.setCsrfToken(null);
    state = const AuthState(null);
  }
}

/// Provider per stato autenticazione
final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

// ============================================================================
// DATA PROVIDERS
// ============================================================================

/// Provider per lista appartamenti
final apartmentsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final client = ref.read(apiClientProvider);
  final list = await client.getApartments();
  return List<Map<String, dynamic>>.from(list);
});

/// Provider per tipi utility disponibili
final utilityTypesProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final client = ref.read(apiClientProvider);
  final list = await client.getUtilityTypes();
  return List<Map<String, dynamic>>.from(list);
});

// ============================================================================
// SELECTION STATE PROVIDERS
// ============================================================================

/// ID appartamento selezionato
final selectedApartmentIdProvider = NotifierProvider<_SelectedApartmentIdNotifier, int?>(
  _SelectedApartmentIdNotifier.new,
);

class _SelectedApartmentIdNotifier extends Notifier<int?> {
  @override
  int? build() => null;
  
  void set(int? value) => state = value;
}

/// Tipo utility selezionato (electricity, water, gas)
final selectedTypeProvider = NotifierProvider<_SelectedTypeNotifier, String>(
  _SelectedTypeNotifier.new,
);

class _SelectedTypeNotifier extends Notifier<String> {
  @override
  String build() => 'electricity';
  
  void set(String value) => state = value;
}

/// Sottotipo utility selezionato (main, laundry) - solo per apt 8
final selectedSubtypeProvider = NotifierProvider<_SelectedSubtypeNotifier, String?>(
  _SelectedSubtypeNotifier.new,
);

class _SelectedSubtypeNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  
  void set(String? value) => state = value;
}

// ============================================================================
// LAST READING PROVIDER (dipende da selezioni correnti)
// ============================================================================

/// Provider per ultima lettura basato su appartamento, tipo e sottotipo selezionati
/// Aggiorna automaticamente quando cambiano le selezioni
final lastReadingProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final client = ref.read(apiClientProvider);
  final aptId = ref.watch(selectedApartmentIdProvider);
  final type = ref.watch(selectedTypeProvider);
  final subtype = ref.watch(selectedSubtypeProvider);

  if (aptId == null) {
    return {'hasHistory': false, 'lastReading': 0};
  }

  return await client.getLastReading(aptId, type, subtype: subtype);
});
