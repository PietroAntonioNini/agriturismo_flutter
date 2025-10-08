# ✅ Deployment Checklist

## Pre-Deployment

### Ambiente Sviluppo
- [ ] Flutter SDK installato (≥ 3.9.2)
- [ ] `flutter doctor` senza errori critici
- [ ] `flutter pub get` completato
- [ ] `flutter analyze` pulito (0 issues)
- [ ] `flutter test` passa (se ci sono test)

### Codice
- [ ] Nessun TODO/FIXME critico
- [ ] Commenti chiari presenti
- [ ] Validazioni input implementate
- [ ] Error handling robusto
- [ ] BASE_URL backend corretto in `providers.dart`

### Testing Funzionale
- [ ] Login con credenziali valide
- [ ] Login con credenziali invalide (messaggio errore)
- [ ] Logout e re-login
- [ ] Caricamento lista appartamenti
- [ ] Pull-to-refresh appartamenti
- [ ] Selezione appartamento
- [ ] Navigazione back
- [ ] Cambio tipo utility (luce/acqua/gas)
- [ ] **Apt 8 + electricity: mostra sottotipo selector**
- [ ] **Apt 8 + acqua/gas: NON mostra sottotipo**
- [ ] **Apt non-8: NON mostra sottotipo**
- [ ] Auto-load ultima lettura
- [ ] Calcolo real-time consumo/costo
- [ ] Validazione lettura < precedente (blocca submit)
- [ ] Submit lettura valida
- [ ] Dialog conferma dopo submit
- [ ] Gestione errori rete (retry)

### Backend
- [ ] Backend online e raggiungibile
- [ ] Endpoint `/api/auth/login` funzionante
- [ ] Endpoint `/apartments` funzionante
- [ ] Endpoint `/utilities/types` funzionante
- [ ] Endpoint `/utilities/last-reading/{id}/{type}` funzionante
- [ ] Endpoint `/utilities/last-reading/{id}/{type}?subtype=laundry` funzionante
- [ ] Endpoint `POST /utilities` funzionante
- [ ] CORS configurato correttamente
- [ ] HTTPS abilitato

---

## Build iOS (Codemagic)

### Setup Repository
- [ ] Repository GitHub creato
- [ ] `.gitignore` corretto (esclude build/, .dart_tool/)
- [ ] Codice pushato su GitHub
- [ ] Branch `main` esistente

### Setup Codemagic
- [ ] Account Codemagic creato
- [ ] Repository connesso
- [ ] `codemagic.yaml` presente nella root
- [ ] Email notifiche configurata
- [ ] Build triggerata su push

### Build Configuration
```yaml
workflows:
  ios-workflow:
    instance_type: mac_mini_m1  ✅
    flutter: stable              ✅
    xcode: latest                ✅
```

### Build Steps
- [ ] Flutter packages downloaded
- [ ] Code analyzed
- [ ] iOS build completato
- [ ] IPA unsigned creato
- [ ] Artifacts disponibili per download

### Download Artifacts
- [ ] File `agriturismo-app.ipa` scaricato
- [ ] Dimensione file ragionevole (< 50MB tipicamente)
- [ ] IPA non corrotto (apribile/estraibile)

---

## Installazione iPhone (AltStore)

### Prerequisiti PC
- [ ] Windows 10/11 o macOS 10.14.4+
- [ ] iTunes installato (Windows) o sistema macOS
- [ ] AltServer scaricato da https://altstore.io
- [ ] AltServer installato e avviato

### Prerequisiti iPhone
- [ ] iOS 12.0 o superiore
- [ ] Apple ID gratuito disponibile
- [ ] iPhone e PC sulla stessa rete Wi-Fi (o USB)
- [ ] "Trova il mio iPhone" disabilitato (opzionale ma consigliato)

### Installazione AltStore su iPhone
- [ ] AltServer in esecuzione su PC
- [ ] iPhone connesso via USB o Wi-Fi
- [ ] AltServer → "Install AltStore" → Seleziona iPhone
- [ ] Inserito Apple ID e password
- [ ] AltStore app visibile su iPhone

### Trust Profile
- [ ] iPhone → Impostazioni → Generali → VPN e gestione dispositivo
- [ ] Selezionato profilo Apple ID
- [ ] Tap "Autorizza" / "Trust"

### Installazione App
- [ ] IPA trasferito su iPhone (AirDrop, Files, iCloud)
- [ ] AltStore aperto su iPhone
- [ ] My Apps → pulsante "+"
- [ ] Selezionato file `agriturismo-app.ipa`
- [ ] Atteso completamento firma e installazione
- [ ] App visibile nella Home Screen

### Trust Developer
- [ ] Impostazioni → Generali → VPN e gestione dispositivo
- [ ] Selezionato profilo sviluppatore
- [ ] Tap "Autorizza"
- [ ] App si apre senza errori

---

## Testing su Dispositivo

### Prima Apertura
- [ ] App si apre senza crash
- [ ] Splash screen (se presente)
- [ ] Login page visibile
- [ ] UI corretta (layout, colori, testo)

### Test Funzionalità
- [ ] Login funziona con connessione internet
- [ ] Toast/snackbar messaggi errore visibili
- [ ] Navigazione fluida tra pagine
- [ ] Tap su elementi responsivi
- [ ] Tastiera appare/scompare correttamente
- [ ] Input fields funzionano
- [ ] Segmented buttons selezionabili
- [ ] Scroll smooth
- [ ] Pull-to-refresh funziona
- [ ] Loading indicators visibili
- [ ] Dialogs si aprono/chiudono

### Test Prestazioni
- [ ] Avvio app < 3 secondi
- [ ] Navigazione istantanea
- [ ] API calls < 2 secondi
- [ ] Nessun lag UI
- [ ] Memoria stabile (no leak)

### Test Edge Cases
- [ ] Modalità aereo (gestisce errore rete)
- [ ] Backend offline (messaggio chiaro)
- [ ] Credenziali errate (messaggio errore)
- [ ] Lettura invalida (blocco submit)
- [ ] Orientamento landscape (se supportato)
- [ ] Dark mode (se supportato)

---

## Manutenzione

### Rinnovo Certificato (ogni 7 giorni)
- [ ] AltServer attivo su PC
- [ ] iPhone e PC su stessa rete
- [ ] AltStore aperto su iPhone
- [ ] "Refresh All" premuto
- [ ] Successo notifica

### Update App
- [ ] Nuovo codice pushato su GitHub
- [ ] Build Codemagic triggerata
- [ ] Nuovo IPA scaricato
- [ ] Vecchia app rimossa da iPhone (opzionale)
- [ ] Nuovo IPA installato via AltStore

### Monitoraggio
- [ ] Logs backend per errori API
- [ ] Feedback utenti raccolto
- [ ] Bug tracking (se presente)
- [ ] Performance monitoring (opzionale)

---

## Troubleshooting

### Build Fallisce
- [ ] Controllato logs Codemagic
- [ ] Verificato `pubspec.yaml` corretto
- [ ] Provato `flutter clean` + rebuild
- [ ] Controllato versione Flutter/Xcode

### AltStore Non Installa
- [ ] Verificato Apple ID corretto
- [ ] Controllato limite 3 app non superato
- [ ] Provato riavvio iPhone
- [ ] Provato disinstalla/reinstalla AltStore

### App Crasha
- [ ] Verificato backend online
- [ ] Controllato BASE_URL
- [ ] Provato reinstallazione app
- [ ] Controllato logs (se disponibili)

### API Errors
- [ ] Verificato connessione internet
- [ ] Controllato token JWT valido
- [ ] Verificato endpoint backend corretti
- [ ] Testato API con Postman/curl

---

## 🎉 Deployment Completato!

Una volta tutti i checkbox ✅:
- App installata su iPhone
- Funzionalità testate
- Utenti possono utilizzarla
- Manutenzione configurata

### Prossimi Passi (opzionale)
- [ ] App Store deployment (richiede Apple Developer Program $99/anno)
- [ ] TestFlight beta testing
- [ ] Analytics integration
- [ ] Crash reporting (Sentry, Firebase)
- [ ] Push notifications
- [ ] Offline mode
- [ ] Dark theme

---

**Buon deployment! 🚀**
