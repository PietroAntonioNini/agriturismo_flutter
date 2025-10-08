# 🚀 Quick Start Guide

## ⚡ Setup Veloce (5 minuti)

### 1️⃣ Installa Flutter
```powershell
# Scarica da https://docs.flutter.dev/get-started/install/windows
# Estrai in C:\flutter
# Aggiungi al PATH: C:\flutter\bin

# Verifica
flutter doctor
```

### 2️⃣ Installa Dipendenze
```powershell
cd agriturismo_flutter
flutter pub get
```

### 3️⃣ Run (Web per test veloce)
```powershell
flutter run -d chrome
```

### 4️⃣ Build iOS (con Codemagic)
1. Push su GitHub
2. Connetti a Codemagic.io
3. Build automatica con `codemagic.yaml`
4. Scarica IPA

### 5️⃣ Installa su iPhone (AltStore)
1. Installa AltServer su PC
2. Installa AltStore su iPhone
3. Carica IPA da AltStore
4. Firma con Apple ID

## 📋 Checklist Pre-Deploy

- [ ] Flutter installato (`flutter doctor` OK)
- [ ] Dipendenze scaricate (`flutter pub get`)
- [ ] Codice analizzato (`flutter analyze`)
- [ ] Backend online (Koyeb)
- [ ] Credenziali di test disponibili
- [ ] Repository GitHub creato
- [ ] Codemagic configurato
- [ ] AltStore installato su iPhone

## 🎯 Test Rapido (senza iPhone)

```powershell
# Test su Chrome
flutter run -d chrome

# Login con credenziali backend
# Testa selezione appartamento
# Testa inserimento lettura
```

## 🐛 Problemi Comuni

### "flutter: command not found"
→ Aggiungi Flutter al PATH di sistema

### Errori pubspec.yaml
→ `flutter pub get` poi `flutter clean`

### Errori API
→ Verifica backend online e BASE_URL in `providers.dart`

## 📞 Supporto

Leggi:
- `README.md` - Guida completa
- `PROGETTO_COMPLETATO.md` - Riepilogo features
- Commenti nel codice

---

**Tutto pronto! Inizia con lo step 1 ☝️**
