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

  /// Effettua login e salva access token
  Future<void> login(String username, String password) async {
    final data = await _client.login(username, password);
    final token = data['accessToken'] as String;
    _client.setAccessToken(token);
    state = AuthState(token);
  }

  /// Logout (pulizia stato locale)
  void logout() {
    _client.setAccessToken(null);
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
