import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers.dart';
import 'add_reading_page.dart';
import 'recent_readings_page.dart';

/// Pagina di selezione appartamento
/// Lista tap-to-select minimale e performante
class SelectApartmentPage extends ConsumerWidget {
  const SelectApartmentPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apartmentsAsync = ref.watch(apartmentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleziona appartamento'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const RecentReadingsPage(),
                ),
              );
            },
            tooltip: 'Letture recenti',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: apartmentsAsync.when(
        data: (apartments) {
          if (apartments.isEmpty) {
            return const Center(child: Text('Nessun appartamento disponibile'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              // Invalida e ricarica la lista
              ref.invalidate(apartmentsProvider);
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: apartments.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final apt = apartments[index];
                return _ApartmentCard(
                  apartment: apt,
                  onTap: () {
                    // Imposta appartamento selezionato e naviga
                    ref.read(selectedApartmentIdProvider.notifier).set(
                        apt['id'] as int);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddReadingPage(apartment: apt),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Errore nel caricamento',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Riprova'),
                onPressed: () => ref.invalidate(apartmentsProvider),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Card per singolo appartamento con informazioni essenziali
class _ApartmentCard extends StatelessWidget {
  final Map<String, dynamic> apartment;
  final VoidCallback onTap;

  const _ApartmentCard({required this.apartment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = apartment['name'] ?? 'Appartamento ${apartment['id']}';
    final floor = apartment['floor'] ?? 0;
    final sqm = apartment['squareMeters'] ?? 0;
    final rooms = apartment['rooms'] ?? 0;
    final status = apartment['status'] ?? 'unknown';

    // Colore status badge
    Color statusColor;
    String statusLabel;
    switch (status) {
      case 'available':
        statusColor = const Color(0xFF43A047); // verde
        statusLabel = 'Disponibile';
        break;
      case 'occupied':
        statusColor = const Color(0xFFE53935); // rosso
        statusLabel = 'Occupato';
        break;
      case 'maintenance':
        statusColor = const Color(0xFFFB8C00); // arancio
        statusLabel = 'Manutenzione';
        break;
      default:
        statusColor = Colors.grey;
        statusLabel = status;
    }

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.layers, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Piano $floor',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.square_foot, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text('$sqm m²', style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(width: 16),
                  Icon(Icons.meeting_room, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '$rooms locali',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
