import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/providers.dart';

/// Pagina inserimento lettura utility
/// Form unico con validazione real-time e feedback immediato
/// Supporta sottotipo lavanderia per appartamento 8
class AddReadingPage extends ConsumerStatefulWidget {
  const AddReadingPage({super.key});

  @override
  ConsumerState<AddReadingPage> createState() => _AddReadingPageState();
}

class _AddReadingPageState extends ConsumerState<AddReadingPage> {
  final _currentReadingController = TextEditingController();
  final _unitCostController = TextEditingController(text: '0.22');

  String? _errorMessage;
  bool _isLoading = false;
  double _consumption = 0;
  double _totalCost = 0;

  @override
  void initState() {
    super.initState();
    // Reset selezioni quando si apre la pagina
    Future.microtask(() {
      ref.read(selectedTypeProvider.notifier).state = 'electricity';
      ref.read(selectedSubtypeProvider.notifier).state = null;
    });
  }

  @override
  void dispose() {
    _currentReadingController.dispose();
    _unitCostController.dispose();
    super.dispose();
  }

  /// Calcola consumo e costo in tempo reale
  void _updateCalculations(double previousReading) {
    final current = double.tryParse(_currentReadingController.text) ?? 0;
    final unitCost = double.tryParse(_unitCostController.text) ?? 0;

    setState(() {
      _consumption = (current - previousReading).clamp(0, double.infinity);
      _totalCost = _consumption * unitCost;

      // Validazione: current deve essere >= previous
      if (current > 0 && current < previousReading) {
        _errorMessage = '⚠️ La lettura attuale deve essere ≥ ultima lettura';
      } else {
        _errorMessage = null;
      }
    });
  }

  /// Gestisce invio lettura al backend
  Future<void> _submitReading() async {
    final aptId = ref.read(selectedApartmentIdProvider);
    final type = ref.read(selectedTypeProvider);
    final subtype = ref.read(selectedSubtypeProvider);
    final lastReadingAsync = ref.read(lastReadingProvider);

    if (aptId == null) {
      setState(() => _errorMessage = 'Errore: nessun appartamento selezionato');
      return;
    }

    // Ottieni ultima lettura
    final lastReading = lastReadingAsync.valueOrNull;
    if (lastReading == null) {
      setState(
        () => _errorMessage = 'Errore: impossibile recuperare ultima lettura',
      );
      return;
    }

    final previousReading = (lastReading['lastReading'] ?? 0).toDouble();
    final currentReading = double.tryParse(_currentReadingController.text) ?? 0;

    // Validazione finale
    if (currentReading <= 0) {
      setState(() => _errorMessage = 'Inserisci una lettura valida');
      return;
    }

    if (currentReading < previousReading) {
      setState(
        () => _errorMessage = 'La lettura attuale deve essere ≥ ultima lettura',
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final unitCost = double.tryParse(_unitCostController.text) ?? 0;

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
        'subtype': subtype,
        'isSpecialReading': false,
      };

      final created = await ref.read(apiClientProvider).createReading(payload);

      if (mounted) {
        // Mostra conferma
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            icon: const Icon(
              Icons.check_circle,
              color: Color(0xFF43A047),
              size: 64,
            ),
            title: const Text('Lettura salvata'),
            content: Text(
              'Lettura #${created['id']} salvata con successo!\n\n'
              'Consumo: ${_consumption.toStringAsFixed(2)}\n'
              'Totale: €${_totalCost.toStringAsFixed(2)}',
              textAlign: TextAlign.center,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Chiudi'),
              ),
            ],
          ),
        );

        // Torna alla lista appartamenti
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      setState(() => _errorMessage = 'Errore: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = ref.watch(selectedTypeProvider);
    final subtype = ref.watch(selectedSubtypeProvider);
    final aptId = ref.watch(selectedApartmentIdProvider);
    final lastReadingAsync = ref.watch(lastReadingProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Inserisci lettura')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info appartamento
            if (aptId != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.home, color: Color(0xFF1E88E5)),
                      const SizedBox(width: 8),
                      Text(
                        'Appartamento ID: $aptId',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Selettore tipo utility
            const Text(
              'Tipo utility',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'electricity',
                  label: Text('⚡ Luce'),
                  icon: Icon(Icons.bolt),
                ),
                ButtonSegment(
                  value: 'water',
                  label: Text('💧 Acqua'),
                  icon: Icon(Icons.water_drop),
                ),
                ButtonSegment(
                  value: 'gas',
                  label: Text('🔥 Gas'),
                  icon: Icon(Icons.local_fire_department),
                ),
              ],
              selected: {type},
              onSelectionChanged: (selected) {
                ref.read(selectedTypeProvider.notifier).state = selected.first;
                // Reset sottotipo quando cambia tipo
                ref.read(selectedSubtypeProvider.notifier).state = null;
                _currentReadingController.clear();
                setState(() {
                  _consumption = 0;
                  _totalCost = 0;
                  _errorMessage = null;
                });
              },
            ),
            const SizedBox(height: 16),

            // Selettore sottotipo (solo per apt 8 + electricity)
            if (aptId == 8 && type == 'electricity') ...[
              const Text(
                'Sottotipo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'main', label: Text('Principale')),
                  ButtonSegment(value: 'laundry', label: Text('Lavanderia')),
                ],
                selected: {subtype ?? 'main'},
                onSelectionChanged: (selected) {
                  ref.read(selectedSubtypeProvider.notifier).state =
                      selected.first;
                  _currentReadingController.clear();
                  setState(() {
                    _consumption = 0;
                    _totalCost = 0;
                    _errorMessage = null;
                  });
                },
              ),
              const SizedBox(height: 16),
            ],

            // Form lettura
            lastReadingAsync.when(
              data: (lastReading) {
                final previousReading = (lastReading['lastReading'] ?? 0)
                    .toDouble();
                final hasHistory = lastReading['hasHistory'] ?? false;
                final lastDate = lastReading['lastReadingDate'] as String?;

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Info ultima lettura
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F7FA),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                hasHistory
                                    ? 'Ultima lettura'
                                    : 'Prima lettura per questo tipo',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                previousReading.toStringAsFixed(2),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E88E5),
                                ),
                              ),
                              if (lastDate != null)
                                Text(
                                  'Data: $lastDate',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Campo lettura attuale
                        TextField(
                          controller: _currentReadingController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d*'),
                            ),
                          ],
                          decoration: InputDecoration(
                            labelText: 'Lettura attuale *',
                            helperText: 'Inserisci il valore del contatore',
                            suffixIcon: const Icon(Icons.edit),
                            errorText: _errorMessage,
                          ),
                          enabled: !_isLoading,
                          onChanged: (_) =>
                              _updateCalculations(previousReading),
                        ),
                        const SizedBox(height: 16),

                        // Campo costo unitario
                        TextField(
                          controller: _unitCostController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d*'),
                            ),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Costo unitario (€)',
                            helperText: 'Costo per unità di misura',
                            suffixIcon: Icon(Icons.euro),
                          ),
                          enabled: !_isLoading,
                          onChanged: (_) =>
                              _updateCalculations(previousReading),
                        ),
                        const SizedBox(height: 24),

                        // Riepilogo calcoli
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF43A047).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF43A047).withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Consumo:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    _consumption.toStringAsFixed(2),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF43A047),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Totale:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '€ ${_totalCost.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E88E5),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Bottone salva
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.save),
                            label: Text(
                              _isLoading ? 'Salvataggio...' : 'Salva lettura',
                            ),
                            onPressed: _isLoading || _errorMessage != null
                                ? null
                                : _submitReading,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 48),
                      const SizedBox(height: 8),
                      Text(
                        'Errore: ${error.toString()}',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(lastReadingProvider),
                        child: const Text('Riprova'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
