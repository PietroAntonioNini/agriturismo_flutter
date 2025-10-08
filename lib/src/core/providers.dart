import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';
import 'auth_service.dart';
import '../models/user.dart';

/// Base URL backend su Koyeb
const baseUrl = 'https://flat-damselfly-agriturismo-backend-47075869.koyeb.app';

/// Provider singleton per AuthService
final authServiceProvider = Provider<AuthService>((ref) => AuthService(baseUrl));

/// Provider singleton per ApiClient (integrato con AuthService)
final apiClientProvider = Provider<ApiClient>((ref) {
  final authService = ref.read(authServiceProvider);
  return ApiClient(baseUrl, authService);
});

// ============================================================================
// AUTH PROVIDERS
// ============================================================================

/// Stato autenticazione con utente completo
class AuthState {
  final User? user;
  final String? accessToken;
  
  const AuthState({this.user, this.accessToken});

  bool get isAuthenticated => user != null && accessToken != null;
}

/// Notifier per gestione autenticazione
class AuthNotifier extends Notifier<AuthState> {
  late final AuthService _authService;

  @override
  AuthState build() {
    _authService = ref.read(authServiceProvider);
    
    // Carica lo stato dall'storage all'avvio
    _loadStoredAuth();
    
    return const AuthState();
  }

  /// Carica autenticazione dal storage
  Future<void> _loadStoredAuth() async {
    await _authService.loadStoredAuth();
    final isLoggedIn = await _authService.isLoggedIn();
    
    if (isLoggedIn) {
      final user = _authService.getCurrentUser();
      final token = _authService.getAccessToken();
      
      if (user != null && token != null) {
        state = AuthState(user: user, accessToken: token);
      }
    }
  }

  /// Effettua login completo seguendo il flusso Angular
  Future<void> login(String username, String password) async {
    final user = await _authService.login(username, password);
    final token = _authService.getAccessToken();
    
    state = AuthState(user: user, accessToken: token);
  }

  /// Logout (pulizia stato locale e storage)
  Future<void> logout() async {
    await _authService.logout();
    state = const AuthState();
  }
}

/// Provider per stato autenticazione
final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

// ============================================================================
// DATA PROVIDERS
// ============================================================================

/// Provider per lista appartamenti (richiede autenticazione)
final apartmentsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  // Verifica autenticazione
  final authState = ref.watch(authProvider);
  if (!authState.isAuthenticated) {
    throw Exception('User not authenticated');
  }

  final client = ref.read(apiClientProvider);
  final list = await client.getApartments();
  return List<Map<String, dynamic>>.from(list);
});

/// Provider per tipi utility disponibili
final utilityTypesProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  // Verifica autenticazione
  final authState = ref.watch(authProvider);
  if (!authState.isAuthenticated) {
    throw Exception('User not authenticated');
  }

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
