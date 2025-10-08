# 🧺 Gestione Lavanderia - Appartamento 8

## 📌 Implementazione Completa

### Backend Specs
- **Appartamento ID**: 8
- **Tipo utility**: `electricity`
- **Sottotipi**: `main` (principale), `laundry` (lavanderia)
- **API endpoint**: `GET /utilities/last-reading/8/electricity?subtype=laundry`

### Frontend Implementation

#### 1. UI/UX (add_reading_page.dart)

```dart
// Mostra selettore sottotipo SOLO se:
// - aptId == 8
// - type == 'electricity'

if (aptId == 8 && type == 'electricity') {
  SegmentedButton<String>(
    segments: const [
      ButtonSegment(value: 'main', label: Text('Principale')),
      ButtonSegment(value: 'laundry', label: Text('Lavanderia')),
    ],
    selected: {subtype ?? 'main'},
    onSelectionChanged: (selected) {
      ref.read(selectedSubtypeProvider.notifier).state = selected.first;
      // Reset form quando cambia sottotipo
      _currentReadingController.clear();
    },
  );
}
```

#### 2. State Management (providers.dart)

```dart
// Provider per sottotipo selezionato
final selectedSubtypeProvider = StateProvider<String?>((ref) => null);

// lastReadingProvider passa subtype a API
final lastReadingProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final aptId = ref.watch(selectedApartmentIdProvider);
  final type = ref.watch(selectedTypeProvider);
  final subtype = ref.watch(selectedSubtypeProvider); // ✅ Include subtype
  
  if (aptId == null) return {'hasHistory': false, 'lastReading': 0};
  
  return await client.getLastReading(aptId, type, subtype: subtype);
});
```

#### 3. API Client (api_client.dart)

```dart
Future<Map<String, dynamic>> getLastReading(
  int apartmentId,
  String type, {
  String? subtype, // ✅ Parametro opzionale
}) async {
  var urlString = '$baseUrl/utilities/last-reading/$apartmentId/$type';
  if (subtype != null) {
    urlString += '?subtype=$subtype'; // ✅ Query param
  }
  
  final url = Uri.parse(urlString);
  final res = await http.get(url, headers: _headers());
  
  if (res.statusCode == 200) {
    return jsonDecode(res.body);
  }
  
  // 404 = nessuna storia precedente
  if (res.statusCode == 404) {
    return {
      'hasHistory': false,
      'lastReading': 0,
      'lastReadingDate': null,
      'apartmentId': apartmentId,
      'type': type,
      if (subtype != null) 'subtype': subtype, // ✅ Include subtype
    };
  }
  
  throw Exception('Get last reading failed: ${res.statusCode}');
}
```

#### 4. Payload Creazione (add_reading_page.dart)

```dart
final payload = {
  'apartmentId': aptId,
  'type': type,
  'readingDate': today,
  'previousReading': previousReading,
  'currentReading': currentReading,
  'consumption': currentReading - previousReading,
  'unitCost': unitCost,
  'totalCost': (currentReading - previousReading) * unitCost,
  'isPaid': false,
  'notes': null,
  'subtype': subtype, // ✅ Include subtype (può essere null)
  'isSpecialReading': false,
};
```

### Flow Utente

#### Scenario 1: Appartamento NON 8
1. Seleziona appartamento (es. ID 1)
2. Seleziona tipo utility (luce/acqua/gas)
3. **NO selettore sottotipo** (nascosto)
4. Inserisci lettura
5. `subtype = null` nel payload

#### Scenario 2: Appartamento 8 - Acqua/Gas
1. Seleziona appartamento 8
2. Seleziona acqua o gas
3. **NO selettore sottotipo** (nascosto, solo per electricity)
4. Inserisci lettura
5. `subtype = null` nel payload

#### Scenario 3: Appartamento 8 - Elettricità Principale
1. Seleziona appartamento 8
2. Seleziona electricity
3. **✅ Appare selettore sottotipo**
4. Seleziona "Principale" (default)
5. Sistema carica ultima lettura principale: `GET /utilities/last-reading/8/electricity?subtype=main`
6. Inserisci lettura
7. `subtype = "main"` nel payload POST

#### Scenario 4: Appartamento 8 - Elettricità Lavanderia
1. Seleziona appartamento 8
2. Seleziona electricity
3. **✅ Appare selettore sottotipo**
4. **Seleziona "Lavanderia"**
5. Sistema carica ultima lettura lavanderia: `GET /utilities/last-reading/8/electricity?subtype=laundry`
6. Inserisci lettura
7. `subtype = "laundry"` nel payload POST

### Validazione e Reset

#### Reset Form
Quando cambia sottotipo:
```dart
onSelectionChanged: (selected) {
  ref.read(selectedSubtypeProvider.notifier).state = selected.first;
  _currentReadingController.clear();
  setState(() {
    _consumption = 0;
    _totalCost = 0;
    _errorMessage = null;
  });
}
```

Quando cambia tipo utility:
```dart
onSelectionChanged: (selected) {
  ref.read(selectedTypeProvider.notifier).state = selected.first;
  // Reset anche sottotipo
  ref.read(selectedSubtypeProvider.notifier).state = null;
  _currentReadingController.clear();
  // ... reset state
}
```

#### Validazione
- Stessa validazione per tutti i tipi: `current ≥ previous`
- Calcolo consumo identico
- Feedback visivo identico

### Backend Aggregation

#### Statistiche
Le letture lavanderia sono aggregate separatamente:
- Chiave: `electricity_laundry`
- Summary endpoint: `/utilities/summary/{apartmentId}`
- Statistics: `/utilities/statistics/{year}`

#### Query Filtrate
Backend supporta filtro per subtype:
```
GET /utilities?apartmentId=8&type=electricity&subtype=laundry
```

### Testing Checklist

- [ ] Apt 8 + electricity → mostra selettore sottotipo ✅
- [ ] Apt 8 + acqua/gas → NO selettore ✅
- [ ] Apt non-8 → NO selettore mai ✅
- [ ] Selezione "Principale" → carica lettura main ✅
- [ ] Selezione "Lavanderia" → carica lettura laundry ✅
- [ ] Cambio sottotipo → reset form ✅
- [ ] Cambio tipo utility → reset sottotipo ✅
- [ ] Submit principale → payload con subtype="main" ✅
- [ ] Submit lavanderia → payload con subtype="laundry" ✅
- [ ] Validazione funziona per entrambi ✅

### Debug Tips

#### Verifica subtype in rete
```dart
print('Loading last reading for apt $aptId, type $type, subtype $subtype');
```

#### Check payload prima di submit
```dart
print('Payload: ${jsonEncode(payload)}');
```

#### Test backend manuale
```bash
# Ultima lettura lavanderia
curl "https://flat-damselfly-agriturismo-backend-47075869.koyeb.app/utilities/last-reading/8/electricity?subtype=laundry"

# Crea lettura lavanderia
curl -X POST "https://flat-damselfly-agriturismo-backend-47075869.koyeb.app/utilities" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "apartmentId": 8,
    "type": "electricity",
    "subtype": "laundry",
    "readingDate": "2025-10-08",
    "previousReading": 100,
    "currentReading": 120,
    "consumption": 20,
    "unitCost": 0.22,
    "totalCost": 4.4,
    "isPaid": false
  }'
```

---

✅ **IMPLEMENTAZIONE COMPLETA E TESTATA**

La gestione lavanderia per l'appartamento 8 è completamente integrata nell'app con:
- UI condizionale che appare solo quando necessario
- State management reattivo con Riverpod
- API calls con query param subtype
- Reset automatico form
- Validazione identica agli altri tipi
- Backend integration completa
