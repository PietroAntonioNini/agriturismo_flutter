# 🏡 Agriturismo Manager - App Flutter iOS

App mobile Flutter per gestione letture utility (luce, acqua, gas) per appartamenti agriturismo.

## 📱 Caratteristiche

- ✅ Autenticazione JWT con backend FastAPI
- ✅ Gestione multi-appartamento
- ✅ Inserimento letture utility con validazione real-time
- ✅ Supporto sottotipo lavanderia per appartamento 8
- ✅ UI moderna con Material Design 3
- ✅ State management con Riverpod
- ✅ Calcolo automatico consumo e costi

## 🛠️ Requisiti

- Flutter SDK 3.9.2 o superiore
- Dart SDK 3.9.2 o superiore
- iOS 12.0+ (per deployment iOS)

## 🚀 Setup Progetto

### 1. Installa Flutter

Scarica Flutter SDK da: https://docs.flutter.dev/get-started/install

```powershell
# Verifica installazione
flutter doctor
```

### 2. Installa dipendenze

```powershell
flutter pub get
```

### 3. Verifica configurazione

```powershell
# Controlla dispositivi disponibili
flutter devices

# Analizza codice
flutter analyze
```

## 🏃‍♂️ Esecuzione

### Debug locale

```powershell
# Chrome/Web
flutter run -d chrome

# iOS Simulator (richiede macOS + Xcode)
flutter run -d "iPhone"

# Dispositivo fisico
flutter run
```

### Build per iOS

```powershell
# Build per iOS (richiede macOS + Xcode)
flutter build ios --release

# Output: build/ios/iphoneos/Runner.app
```

## 📦 Deployment iOS senza Xcode (con Codemagic)

### Step 1: Repository GitHub

1. Crea repository GitHub
2. Push del codice:

```powershell
git init
git add .
git commit -m "Initial commit"
git remote add origin <your-repo-url>
git push -u origin main
```

### Step 2: Configurazione Codemagic

1. Vai su https://codemagic.io
2. Connetti repository GitHub
3. Crea nuovo workflow Flutter:
   - **Platform**: iOS
   - **Flutter version**: Stable (3.24+)
   - **Build mode**: Release
   - **Code signing**: None (unsigned IPA per test)

### Step 3: File codemagic.yaml

Crea `codemagic.yaml` nella root del progetto con questa configurazione per build iOS unsigned.

### Step 4: Scarica IPA

Dopo la build, scarica `app-unsigned.ipa` dagli Artifacts.

## 📲 Installazione su iPhone (con AltStore)

### Requisiti

- iPhone con iOS 12+
- PC Windows o Mac
- Cavo USB o stesso Wi-Fi
- Apple ID gratuito

### Step 1: Installa AltServer

1. Scarica AltServer: https://altstore.io
2. Installa AltServer sul PC
3. Collega iPhone via USB o Wi-Fi

### Step 2: Installa AltStore su iPhone

1. Avvia AltServer sul PC
2. Icona AltServer nella system tray → "Install AltStore"
3. Seleziona il tuo iPhone
4. Inserisci Apple ID e password
5. AltStore viene installato su iPhone

### Step 3: Installa l'app

1. Apri AltStore su iPhone
2. Vai su "My Apps" → pulsante "+"
3. Seleziona il file `.ipa` scaricato
4. AltStore firma e installa l'app (validità 7 giorni)

### Step 4: Trust Developer

1. Vai su iPhone → Impostazioni → Generali
2. Gestione profili e dispositivi
3. Seleziona il tuo Apple ID e "Autorizza"

## 🔄 Rinnovo certificati (ogni 7 giorni)

AltStore tenta il rinnovo automatico se:
- AltServer è attivo sul PC
- iPhone e PC sono sulla stessa rete Wi-Fi
- AltStore in background su iPhone

Oppure manualmente:
1. Apri AltStore su iPhone
2. "My Apps" → "Refresh All"

## 🔧 Configurazione API

Backend URL configurato in `lib/src/core/providers.dart`:

```dart
const baseUrl = 'https://flat-damselfly-agriturismo-backend-47075869.koyeb.app';
```

### Endpoints utilizzati

- `POST /api/auth/login` - Autenticazione
- `GET /apartments` - Lista appartamenti
- `GET /utilities/types` - Tipi utility
- `GET /utilities/last-reading/{aptId}/{type}` - Ultima lettura
- `POST /utilities` - Crea lettura

## 🎨 Struttura Progetto

```
lib/
├── main.dart                          # Entry point con ProviderScope
├── src/
    ├── app.dart                       # Widget principale MaterialApp
    ├── theme.dart                     # Tema custom
    ├── core/
    │   ├── api_client.dart           # Client HTTP per API backend
    │   └── providers.dart            # Riverpod providers e state
    └── pages/
        ├── login_page.dart           # Pagina autenticazione
        ├── select_apartment_page.dart # Selezione appartamento
        └── add_reading_page.dart     # Inserimento lettura
```

## 🧪 Testing

```powershell
# Run tests
flutter test

# Coverage report
flutter test --coverage
```

## 📝 Credenziali Test Backend

Usa le credenziali fornite dal backend per il login.

## 🐛 Troubleshooting

### Errore: "Package not found"

```powershell
flutter pub get
flutter clean
flutter pub get
```

### Errore build iOS

- Verifica Xcode installato (solo macOS)
- Usa Codemagic per build remota

### Errore rete/API

- Verifica connessione internet
- Controlla BASE_URL in `providers.dart`
- Backend deve essere online (Koyeb)

### AltStore non firma app

- Verifica Apple ID corretto
- Prova a rimuovere e reinstallare AltStore
- Assicurati di non superare 3 app installate (limite Apple ID gratuito)

## 📚 Risorse

- [Flutter Documentation](https://docs.flutter.dev/)
- [Riverpod Documentation](https://riverpod.dev/)
- [AltStore Guide](https://altstore.io/faq/)
- [Codemagic Docs](https://docs.codemagic.io/)

## 🔒 Sicurezza

- Token JWT salvato in memoria (non persistente)
- HTTPS obbligatorio per tutte le chiamate
- Validazione lato client e server

## 📄 License

Progetto privato per uso interno agriturismo.

---

**Nota importante**: Per build e deployment iOS senza Mac, usa Codemagic. Per installazione su dispositivo fisico senza Mac, usa AltStore con certificato Apple ID gratuito (validità 7 giorni).
