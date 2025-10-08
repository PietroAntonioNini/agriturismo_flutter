import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/app.dart';

/// Entry point dell'applicazione
/// Wrappa l'app con ProviderScope per Riverpod
void main() {
  runApp(const ProviderScope(child: MyApp()));
}
