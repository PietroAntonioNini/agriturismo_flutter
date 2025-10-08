# 🏗️ Architettura App - Agriturismo Manager

## 📐 Struttura a Livelli

```
┌─────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                    │
│  ┌────────────┐  ┌─────────────┐  ┌──────────────┐     │
│  │ LoginPage  │→ │ ApartmentPage│→ │ ReadingPage  │     │
│  └────────────┘  └──────────────┘  └──────────────┘     │
│         ↓                ↓                  ↓            │
└─────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────┐
│                   STATE MANAGEMENT                       │
│  ┌──────────────────────────────────────────────────┐   │
│  │             Riverpod Providers                   │   │
│  │  • authProvider (StateNotifierProvider)         │   │
│  │  • apartmentsProvider (FutureProvider)          │   │
│  │  • selectedApartmentIdProvider (StateProvider)  │   │
│  │  • selectedTypeProvider (StateProvider)         │   │
│  │  • selectedSubtypeProvider (StateProvider)      │   │
│  │  • lastReadingProvider (FutureProvider)         │   │
│  └──────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────┐
│                     DATA LAYER                           │
│  ┌────────────────────────────────────────────────┐     │
│  │              ApiClient                         │     │
│  │  • login(username, password)                   │     │
│  │  • getApartments()                             │     │
│  │  • getUtilityTypes()                           │     │
│  │  • getLastReading(aptId, type, subtype?)       │     │
│  │  • createReading(payload)                      │     │
│  └────────────────────────────────────────────────┘     │
└─────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────┐
│                   BACKEND API                            │
│  Koyeb: flat-damselfly-agriturismo-backend-47075869     │
│  • FastAPI + SQLAlchemy + JWT Auth                      │
└─────────────────────────────────────────────────────────┘
```

## 🔄 Data Flow - Inserimento Lettura

```
User Action                 State                   API Call
───────────                ─────                   ────────

1. Seleziona Apt 8 →  selectedApartmentIdProvider → ∅
                           = 8

2. Seleziona Electricity → selectedTypeProvider → ∅
                           = 'electricity'
                           
3. UI mostra sottotipo →  (Conditional render) → ∅
   (aptId==8 && type=='electricity')

4. Seleziona Lavanderia → selectedSubtypeProvider → ∅
                           = 'laundry'

5. Auto-load ultima →     lastReadingProvider → GET /utilities/
   lettura                 triggers              last-reading/8/
                                                electricity?
                                                subtype=laundry

6. Backend risponde ←     ← ← ← ← ← ← ← ← ←  { lastReading: 500,
                                                 lastReadingDate: ... }

7. Form pre-compilato →   UI update → ∅
   con 500 come previous

8. User inserisce 520 →   Local state → ∅
                          _currentReadingController
                          = '520'

9. Real-time calc →       setState() → ∅
   consumo: 20            _consumption = 20
   costo: 4.4             _totalCost = 4.4

10. User tap "Salva" →    Validation → ∅
                          520 >= 500 ✅

11. Submit →              apiClient.createReading() → POST /utilities
                                                       {
                                                         apartmentId: 8,
                                                         type: 'electricity',
                                                         subtype: 'laundry',
                                                         ...
                                                       }

12. Success ←             ← ← ← ← ← ← ← ← ← ← ←  { id: 101, ... }

13. Show dialog →         UI feedback → ∅
    "Lettura salvata!"

14. Navigate back →       Navigator.pop() → ∅
```

## 🎨 Widget Tree - AddReadingPage

```
Scaffold
├── AppBar
│   └── Text("Inserisci lettura")
└── SingleChildScrollView
    └── Column
        ├── Card (Info appartamento)
        │   └── Row
        │       ├── Icon(home)
        │       └── Text("Appartamento ID: 8")
        │
        ├── SegmentedButton (Tipo utility)
        │   ├── electricity
        │   ├── water
        │   └── gas
        │
        ├── [Conditional] SegmentedButton (Sottotipo)
        │   │   (solo se aptId==8 && type=='electricity')
        │   ├── main
        │   └── laundry
        │
        └── lastReadingProvider.when(
            data: (lastReading) => Card (Form)
                └── Column
                    ├── Container (Ultima lettura)
                    │   └── Text("500.00")
                    │
                    ├── TextField (Lettura attuale)
                    │   └── onChanged → _updateCalculations()
                    │
                    ├── TextField (Costo unitario)
                    │
                    ├── Container (Riepilogo)
                    │   ├── Text("Consumo: 20.00")
                    │   └── Text("Totale: € 4.40")
                    │
                    └── ElevatedButton ("Salva")
                        └── onPressed → _submitReading()
            loading: () => CircularProgressIndicator()
            error: (e) => ErrorWidget()
        )
```

## 🔐 Security Flow

```
1. Login
   ┌────────────┐
   │ User Input │ username + password
   └─────┬──────┘
         ↓
   ┌────────────────────────────────────┐
   │ POST /api/auth/login               │
   │ Content-Type: x-www-form-urlencoded│
   └──────────────┬─────────────────────┘
                  ↓
   ┌────────────────────────────────────┐
   │ Backend JWT validation             │
   │ Returns: { accessToken, ... }      │
   └──────────────┬─────────────────────┘
                  ↓
   ┌────────────────────────────────────┐
   │ ApiClient.setAccessToken(token)    │
   │ authProvider.state = AuthState(tok)│
   └────────────────────────────────────┘

2. Authenticated Requests
   ┌────────────────────────────────────┐
   │ Any API call (apartments, utils)   │
   └──────────────┬─────────────────────┘
                  ↓
   ┌────────────────────────────────────┐
   │ _headers() adds:                   │
   │ "Authorization: Bearer <token>"    │
   └──────────────┬─────────────────────┘
                  ↓
   ┌────────────────────────────────────┐
   │ Backend validates JWT              │
   │ Returns data if valid, 401 if not  │
   └────────────────────────────────────┘
```

## 🎯 State Management Pattern

### Provider Dependencies

```
authProvider (root)
    ↓
apiClientProvider (depends on nothing)
    ↓
apartmentsProvider (depends on apiClient)
    ↓
selectedApartmentIdProvider (user selection)
    ↓
selectedTypeProvider (user selection)
    ↓
selectedSubtypeProvider (user selection)
    ↓
lastReadingProvider (depends on: apiClient, selectedApartmentId, selectedType, selectedSubtype)
```

### Reactive Updates

```
User change:    selectedTypeProvider.state = 'water'
                          ↓
Riverpod detects:  lastReadingProvider dependency changed
                          ↓
Auto-refresh:      lastReadingProvider re-executes
                          ↓
API call:          GET /utilities/last-reading/{aptId}/water
                          ↓
UI rebuild:        Consumer widgets rebuild with new data
```

## 🧩 Component Responsibilities

### LoginPage
- ✅ User input (username, password)
- ✅ Form validation
- ✅ Error display
- ✅ Loading state
- ✅ Navigation to SelectApartmentPage

### SelectApartmentPage
- ✅ Fetch apartments list
- ✅ Display as cards
- ✅ Handle loading/error states
- ✅ Pull-to-refresh
- ✅ Navigate to AddReadingPage with selected ID

### AddReadingPage
- ✅ Type selection (electricity/water/gas)
- ✅ Conditional subtype selection (apt 8 only)
- ✅ Fetch last reading
- ✅ Form input (current reading, unit cost)
- ✅ Real-time calculation
- ✅ Validation
- ✅ Submit to backend
- ✅ Success/error feedback

### ApiClient
- ✅ HTTP calls with http package
- ✅ JWT token management
- ✅ Error handling and parsing
- ✅ 404 graceful handling (no history)

### Providers
- ✅ Global state management
- ✅ Caching (FutureProvider)
- ✅ Reactive dependencies
- ✅ Type-safe state

## 📊 Performance Optimizations

### 1. Lazy Loading
```dart
FutureProvider → executes only when watched
const widgets → prevents unnecessary rebuilds
```

### 2. Selective Rebuilds
```dart
ref.watch(selectedTypeProvider) → only widgets watching this rebuild
ref.read() → no rebuild, just read value
```

### 3. Input Debouncing
```dart
TextField onChanged → immediate setState for UX
Backend validation → only on submit
```

### 4. Caching
```dart
FutureProvider → caches result until invalidated
ref.invalidate() → manual cache clear
```

### 5. Memory Management
```dart
TextEditingController dispose() in dispose()
StateProvider auto-cleanup by Riverpod
```

## 🎨 Theme Architecture

```
ThemeData
├── ColorScheme
│   ├── primary: #1E88E5 (blu)
│   └── secondary: #43A047 (verde)
├── scaffoldBackgroundColor: #F5F7FA
├── AppBarTheme
│   ├── elevation: 0
│   ├── centerTitle: true
│   └── backgroundColor: primary
├── CardThemeData
│   ├── elevation: 2
│   └── borderRadius: 12
├── InputDecorationTheme
│   ├── border: OutlineInputBorder
│   ├── filled: true
│   └── fillColor: white
└── ElevatedButtonThemeData
    ├── padding: 32x16
    └── borderRadius: 8
```

---

✨ **Architettura pulita, modulare e scalabile**
✨ **Separazione concerns perfetta**
✨ **State management reattivo ed efficiente**
✨ **Performance ottimizzate**
