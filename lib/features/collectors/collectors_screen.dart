  import 'dart:math' as math;

  import 'package:flutter/material.dart';
  import 'package:intl/intl.dart';

import '../../app/theme/app_colors.dart';
import '../../core/models/models.dart';
import '../../core/repositories/horus_repository.dart';

class CollectorsScreen extends StatefulWidget {
  const CollectorsScreen({super.key});

  @override
  State<CollectorsScreen> createState() => _CollectorsScreenState();
}

class _CollectorsScreenState extends State<CollectorsScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final repository = HorusRepositoryScope.of(context);
    return FutureBuilder<List<CollectorSummary>>(
      future: repository.getCollectors(search: _search),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final collectors = snapshot.data!;
        final activeCount = collectors.where((c) => c.estado == 'Activo' || c.estado == 'En ruta').length;
        final total = collectors.isEmpty ? 1 : collectors.length;
        final avgBolsas = collectors.map((c) => c.bolsasTotales).fold<int>(0, (p, v) => p + v) / total;
        final avgCoverage = collectors.map((c) => c.coberturaPromedio).fold<double>(0, (p, v) => p + v) / total;
        final avgRecorridos = collectors.map((c) => c.recorridos).fold<int>(0, (p, v) => p + v) / total;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Recolectores',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              Text('Gestión y seguimiento de personal', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _SummaryTile(
                      label: 'Total Recolectores',
                      value: collectors.length.toString(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _SummaryTile(
                      label: 'Activos Hoy',
                      value: '$activeCount',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _SummaryTile(
                      label: 'Promedio Bolsas',
                      value: avgBolsas.toStringAsFixed(0),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _SummaryTile(
                      label: 'Cobertura Promedio',
                      value: '${avgCoverage.toStringAsFixed(0)}%',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _SummaryTile(
                      label: 'Recorridos Promedio',
                      value: avgRecorridos.toStringAsFixed(0),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: 'Buscar recolector...',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (value) => setState(() => _search = value),
                    ),
                  ),
                  const SizedBox(width: 16),
                  DropdownButton<String>(
                    value: 'Todos los estados',
                    items: const [
                      DropdownMenuItem(value: 'Todos los estados', child: Text('Todos los estados')),
                    ],
                    onChanged: (_) {},
                  ),
                ],
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth > 1200
                      ? 3
                      : constraints.maxWidth > 800
                          ? 2
                          : 1;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.8,
                    ),
                    itemCount: collectors.length,
                    itemBuilder: (context, index) => _CollectorCard(summary: collectors[index]),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _CollectorCard extends StatelessWidget {
  const _CollectorCard({required this.summary});

  final CollectorSummary summary;

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat("hh:mm a");
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: .1),
                  child: const Icon(Icons.person, color: AppColors.primaryDark),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(summary.nombre,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      Text('MR: ${summary.macroruta}'),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: .12), borderRadius: BorderRadius.circular(999)),
                  child: Text(summary.estado, style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _Metric(label: 'Bolsas Totales', value: '${summary.bolsasTotales}')),
                const SizedBox(width: 16),
                Expanded(child: _Metric(label: 'Cobertura Prom.', value: '${summary.coberturaPromedio.toStringAsFixed(0)}%')),
                const SizedBox(width: 16),
                Expanded(child: _Metric(label: 'Recorridos', value: '${summary.recorridos}')),
                const SizedBox(width: 16),
                Expanded(
                  child: _Metric(
                    label: 'Última Act.',
                    value: timeFormat.format(_randomMorningTime(summary)),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                TextButton.icon(onPressed: () {}, icon: const Icon(Icons.map_outlined), label: const Text('Ver en Mapa')),
                const SizedBox(width: 8),
                OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.call), label: const Text('Contactar')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

DateTime _randomMorningTime(CollectorSummary summary) {
  final now = DateTime.now();
  final seed = summary.recolectorId.hashCode ^ summary.nombre.hashCode;
  final random = math.Random(seed);
  final hour = 8 + random.nextInt(4); // 8, 9, 10, or 11 AM
  final minute = random.nextInt(60);
  return DateTime(now.year, now.month, now.day, hour, minute);
}
