import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/providers.dart';

/// Provider per l'appartamento selezionato nel filtro (null = tutti)
final selectedFilterApartmentProvider = StateProvider<int?>((ref) => null);

/// Pagina per visualizzare le letture recenti (ultimi 10 giorni)
/// Con possibilità di eliminarle rapidamente
class RecentReadingsPage extends ConsumerWidget {
  const RecentReadingsPage({super.key});

  /// Formatta la data in formato leggibile
  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (_) {
      return dateString;
    }
  }

  /// Restituisce il nome leggibile del tipo di utility
  String _getUtilityTypeName(String type) {
    switch (type) {
      case 'electricity':
        return '⚡ Luce';
      case 'water':
        return '💧 Acqua';
      case 'gas':
        return '🔥 Gas';
      default:
        return type;
    }
  }

  /// Restituisce il colore associato al tipo di utility
  Color _getUtilityTypeColor(String type) {
    switch (type) {
      case 'electricity':
        return Colors.amber;
      case 'water':
        return Colors.blue;
      case 'gas':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  /// Mostra dialog di conferma eliminazione
  Future<bool> _showDeleteConfirmation(
    BuildContext context,
    Map<String, dynamic> reading,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina lettura'),
        content: Text(
          'Sei sicuro di voler eliminare la lettura ${_getUtilityTypeName(reading['type'] ?? '')} '
          'del ${_formatDate(reading['readingDate']?.toString())}?\n\n'
          'Questa azione non può essere annullata.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );

    return confirmed ?? false;
  }

  /// Elimina una lettura
  Future<void> _deleteReading(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> reading,
  ) async {
    final id = reading['id'];
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Errore: ID lettura non valido'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Mostra conferma
    final confirmed = await _showDeleteConfirmation(context, reading);
    if (!confirmed) return;

    // Mostra loader
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    try {
      final client = ref.read(apiClientProvider);
      final success = await client.deleteReading(id);

      if (context.mounted) {
        // Chiudi loader
        Navigator.of(context).pop();

        if (success) {
          // Invalida il provider per ricaricare la lista
          ref.invalidate(recentReadingsProvider);

          // Mostra messaggio di successo
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text('Lettura eliminata con successo'),
                  ),
                ],
              ),
              backgroundColor: Color(0xFF43A047),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          throw Exception('Eliminazione fallita');
        }
      }
    } catch (e) {
      if (context.mounted) {
        // Chiudi loader se ancora aperto
        Navigator.of(context).pop();

        // Mostra errore
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore durante l\'eliminazione: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readingsAsync = ref.watch(recentReadingsProvider);
    final apartmentsAsync = ref.watch(apartmentsProvider);
    final selectedApartmentId = ref.watch(selectedFilterApartmentProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Letture recenti'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(recentReadingsProvider);
              ref.invalidate(apartmentsProvider);
            },
            tooltip: 'Aggiorna',
          ),
        ],
      ),
      body: readingsAsync.when(
        data: (readings) {
          // Crea una mappa apartmentId -> apartmentName per lookup veloce
          final apartmentMap = <int, String>{};
          apartmentsAsync.whenData((apartments) {
            for (final apt in apartments) {
              apartmentMap[apt['id'] as int] = apt['name'] as String;
            }
          });

          // Filtra le letture per appartamento se selezionato
          final filteredReadings = selectedApartmentId == null
              ? readings
              : readings
                  .where((r) => r['apartmentId'] == selectedApartmentId)
                  .toList();

          return Column(
            children: [
              // Filtro appartamenti
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: apartmentsAsync.when(
                  data: (apartments) {
                    return DropdownButtonFormField<int?>(
                      value: selectedApartmentId,
                      decoration: const InputDecoration(
                        labelText: 'Filtra per appartamento',
                        prefixIcon: Icon(Icons.filter_list),
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Tutti gli appartamenti'),
                        ),
                        ...apartments.map((apt) {
                          return DropdownMenuItem<int?>(
                            value: apt['id'] as int,
                            child: Text(apt['name'] as String),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        ref.read(selectedFilterApartmentProvider.notifier).state = value;
                      },
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),

              // Lista letture
              Expanded(
                child: filteredReadings.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              selectedApartmentId == null
                                  ? 'Nessuna lettura recente'
                                  : 'Nessuna lettura per questo appartamento',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Le letture degli ultimi 10 giorni\nappariranno qui',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(recentReadingsProvider);
                          ref.invalidate(apartmentsProvider);
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredReadings.length,
                          itemBuilder: (context, index) {
                            final reading = filteredReadings[index];
                            final type = reading['type'] ?? 'unknown';
                            final apartmentId = reading['apartmentId'] as int;
                            // Usa il nome dall'apartmentMap, fallback al nome nel reading o ID
                            final apartmentName = apartmentMap[apartmentId] ??
                                reading['apartmentName'] ??
                                'Appartamento $apartmentId';
                            final consumption = (reading['consumption'] ?? 0).toDouble();
                            final totalCost = (reading['totalCost'] ?? 0).toDouble();
                            final date = reading['readingDate']?.toString();
                            final subtype = reading['subtype'];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      // Opzionale: mostra dettagli completi
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header: tipo utility e appartamento
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _getUtilityTypeColor(type)
                                      .withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _getUtilityTypeName(type),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _getUtilityTypeColor(type)
                                        .withValues(alpha: 1.0),
                                  ),
                                ),
                              ),
                              if (subtype != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    subtype == 'laundry' ? '🧺 Lavanderia' : '🏠 Principale',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteReading(
                                  context,
                                  ref,
                                  reading,
                                ),
                                tooltip: 'Elimina',
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Appartamento
                          Row(
                            children: [
                              const Icon(
                                Icons.home,
                                size: 18,
                                color: Color(0xFF1E88E5),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                apartmentName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Data
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _formatDate(date),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Consumo e costo
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F7FA),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Consumo',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      consumption.toStringAsFixed(2),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF43A047),
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  width: 1,
                                  height: 40,
                                  color: Colors.grey.shade300,
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Totale',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '€ ${totalCost.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E88E5),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Errore nel caricamento delle letture',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Riprova'),
                  onPressed: () => ref.invalidate(recentReadingsProvider),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
