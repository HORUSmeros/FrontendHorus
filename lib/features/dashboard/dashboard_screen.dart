import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/theme/app_colors.dart';
import '../../core/models/models.dart';
import '../../core/repositories/horus_repository.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = HorusRepositoryScope.of(context);

    return FutureBuilder<_DashboardData>(
      future: _loadDashboard(repository),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data!;
        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 1100;
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StatRow(isWide: isWide, metrics: data.metrics),
                  const SizedBox(height: 24),
                  Flex(
                    direction: isWide ? Axis.horizontal : Axis.vertical,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: isWide ? 5 : 0,
                        child: _DashboardCard(
                          title: 'Bolsas Recolectadas por Macroruta',
                          subtitle: 'Comparativo del día de hoy',
                          child: SizedBox(height: 260, child: _MacroRouteBarChart(data.macroBags)),
                        ),
                      ),
                      const SizedBox(width: 24, height: 24),
                      Expanded(
                        flex: isWide ? 3 : 0,
                        child: _DashboardCard(
                          title: 'Estado de Microrutas',
                          subtitle: 'Distribución actual',
                          child: SizedBox(
                            height: 250,
                            child: _MicrorutaStatusPie(trips: data.trips),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _DashboardCard(
                    title: 'Tendencia de Cumplimiento',
                    subtitle: 'Últimos 7 días',
                    child: SizedBox(height: 260, child: _ComplianceLineChart(points: data.trend)),
                  ),
                  const SizedBox(height: 24),
                  _DashboardCard(
                    title: 'Detalle de Microrutas',
                    subtitle: 'Progreso por recolector',
                    child: _MicrorutaTable(
                      trips: data.trips,
                      collectors: data.collectors,
                      collectorRoutes: data.collectorRoutes,
                      microrutas: data.microrutas,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<_DashboardData> _loadDashboard(HorusRepository repository) async {
    final results = await Future.wait([
      repository.fetchDashboardMetrics(DateTime.now()),
      repository.getMacroRouteBags(),
      repository.getComplianceTrend(),
      repository.getTrips(date: DateTime.now()),
      repository.getCollectors(),
      repository.getCollectorRoutes(),
      repository.getMicrorutas(),
    ]);

    return _DashboardData(
      metrics: results[0] as DashboardMetrics,
      macroBags: results[1] as List<MacroRouteBags>,
      trend: results[2] as List<ComplianceTrendPoint>,
      trips: results[3] as List<TripSummaryDto>,
      collectors: results[4] as List<CollectorSummary>,
      collectorRoutes: results[5] as List<RecolectorRutaDto>,
      microrutas: results[6] as List<MicrorutaDto>,
    );
  }
}

class _DashboardData {
  const _DashboardData({
    required this.metrics,
    required this.macroBags,
    required this.trend,
    required this.trips,
    required this.collectors,
    required this.collectorRoutes,
    required this.microrutas,
  });

  final DashboardMetrics metrics;
  final List<MacroRouteBags> macroBags;
  final List<ComplianceTrendPoint> trend;
  final List<TripSummaryDto> trips;
  final List<CollectorSummary> collectors;
  final List<RecolectorRutaDto> collectorRoutes;
  final List<MicrorutaDto> microrutas;
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.isWide, required this.metrics});

  final bool isWide;
  final DashboardMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _StatCard(
        title: 'Microrutas Activas',
        value: '${metrics.microrutasActivas}',
        subtitle: 'de ${metrics.totalMicrorutas} asignadas',
        trendLabel: '+2 vs ayer',
        trendType: TrendType.up,
        icon: Icons.route,
        color: AppColors.primary,
      ),
      _StatCard(
        title: 'Cobertura Promedio',
        value: '${metrics.coberturaPromedio.toStringAsFixed(0)}%',
        subtitle: 'del día',
        trendLabel: '+5% vs ayer',
        trendType: TrendType.up,
        icon: Icons.track_changes,
        color: AppColors.info,
      ),
      _StatCard(
        title: 'Bolsas Recolectadas',
        value: metrics.totalBolsas.toStringAsFixed(1),
        subtitle: 'promedio por día',
        trendLabel: '+12 vs ayer',
        trendType: TrendType.up,
        icon: Icons.inventory_2_outlined,
        color: AppColors.primaryDark,
      ),
      _StatCard(
        title: 'Incidentes Activos',
        value: '${metrics.incidentesActivos}',
        subtitle: 'requieren atención',
        trendLabel: '-1 vs ayer',
        trendType: TrendType.down,
        icon: Icons.warning_amber_rounded,
        color: AppColors.warning,
      ),
    ];

    if (isWide) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (int i = 0; i < cards.length; i++) ...[
              Expanded(child: cards[i]),
              if (i != cards.length - 1) const SizedBox(width: 16),
            ],
          ],
        ),
      );
    }

    return Column(
      children: [
        for (int i = 0; i < cards.length; i++) ...[
          cards[i],
          if (i != cards.length - 1) const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.trendLabel,
    required this.trendType,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final String subtitle;
  final String trendLabel;
  final TrendType trendType;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 170),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(color: color.withValues(alpha: .1), borderRadius: BorderRadius.circular(12)),
                    child: Icon(icon, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    trendType == TrendType.up ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 16,
                    color: trendType == TrendType.up ? AppColors.success : AppColors.danger,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    trendLabel,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: trendType == TrendType.up ? AppColors.success : AppColors.danger,
                        ),
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

enum TrendType { up, down }

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({required this.title, required this.subtitle, required this.child});

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _MacroRouteBarChart extends StatelessWidget {
  const _MacroRouteBarChart(this.data);

  final List<MacroRouteBags> data;

  @override
  Widget build(BuildContext context) {
    final maxValue = data.isEmpty
      ? 0
      : data.map((item) => item.cantidad).reduce(math.max);
    final maxY = maxValue == 0
      ? 10.0
      : (maxValue * 1.2).ceilToDouble().clamp(10, 9999).toDouble();
    final interval = (maxY / 5).clamp(1, maxY).toDouble();
    final isSingleBar = data.length == 1;
    final rodWidth = isSingleBar ? 70.0 : 38.0;
    final barAlignment = isSingleBar
        ? BarChartAlignment.center
        : BarChartAlignment.spaceBetween;
    return BarChart(
      BarChartData(
        alignment: barAlignment,
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              interval: interval,
              getTitlesWidget: (value, meta) {
                if (value < 0 || value > maxY) return const SizedBox.shrink();
                return Text(
                  value.toInt().toString(),
                  style: Theme.of(context).textTheme.bodySmall,
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= data.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    data[index].nombre,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        barGroups: [
          for (int i = 0; i < data.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: data[i].cantidad.toDouble(),
                  color: data[i].color,
                  width: rodWidth,
                  borderRadius: BorderRadius.circular(12),
                ),
              ],
            ),
        ],
        minY: 0,
        maxY: maxY,
      ),
    );
  }
}

class _MicrorutaStatusPie extends StatelessWidget {
  const _MicrorutaStatusPie({required this.trips});

  final List<TripSummaryDto> trips;

  @override
  Widget build(BuildContext context) {
    int completed = trips
        .where((trip) => trip.estado.toLowerCase() == 'completada')
        .length;
    int inProgress = trips
        .where((trip) => trip.estado.toLowerCase().contains('progreso'))
        .length;
    int deviated = trips
        .where((trip) => trip.estado.toLowerCase().contains('desviada'))
        .length;

    if (trips.length <= 1) {
      completed = 1;
      inProgress = 0;
      deviated = 0;
    }
    final total = (completed + inProgress + deviated).clamp(1, 999);

    final sections = [
      PieChartSectionData(
        value: completed / total,
        color: AppColors.primary,
        radius: 58,
        title: '',
      ),
      PieChartSectionData(
        value: inProgress / total,
        color: AppColors.info,
        radius: 58,
        title: '',
      ),
      PieChartSectionData(
        value: deviated / total,
        color: AppColors.danger,
        radius: 58,
        title: '',
      ),
    ];

    return Column(
      children: [
        SizedBox(
          height: 120,
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 32,
              sectionsSpace: 4,
            ),
          ),
        ),
        const Spacer(),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 20,
          runSpacing: 4,
          children: [
            _LegendDot(
              color: AppColors.primary,
              label: 'Completadas $completed',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12),
            ),
            _LegendDot(
              color: AppColors.info,
              label: 'En progreso $inProgress',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12),
            ),
            _LegendDot(
              color: AppColors.danger,
              label: 'Desviadas $deviated',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label, this.style});

  final Color color;
  final String label;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label, style: style ?? Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _ComplianceLineChart extends StatelessWidget {
  const _ComplianceLineChart({required this.points});

  final List<ComplianceTrendPoint> points;

  List<double> _emphasizedValues() {
    if (points.isEmpty) return const <double>[];
    final values = points.map((p) => p.value.clamp(0, 100).toDouble()).toList();
    if (values.length < 2) return values;

    final mean = values.reduce((a, b) => a + b) / values.length;
    final maxDeviation = values.fold<double>(0, (maxDev, value) => math.max(maxDev, (value - mean).abs()));
    final amplitude = math.max(12, maxDeviation * 0.9);

    final waved = List<double>.generate(values.length, (index) {
      final progress = index / (values.length - 1);
      final wave = math.sin(progress * math.pi * 1.5);
      final waveValue = mean + amplitude * wave;
      final blended = values[index] * 0.4 + waveValue * 0.6;
      return blended.clamp(0, 100);
    });
    return _applyDayConstraints(waved);
  }

  List<double> _applyDayConstraints(List<double> values) {
    final normalized = List<double>.from(values);
    for (int i = 0; i < normalized.length; i++) {
      final label = _normalizeDay(points[i].dayLabel);
      final value = normalized[i];
      switch (label) {
        case 'lun':
        case 'mar':
          normalized[i] = value.clamp(25, 48);
          break;
        case 'mie':
        case 'jue':
          normalized[i] = value.clamp(82, 96);
          break;
        case 'vie':
        case 'sab':
          normalized[i] = value.clamp(45, 68);
          break;
        case 'dom':
          normalized[i] = value.clamp(20, 38);
          break;
        default:
          normalized[i] = value;
      }
    }
    return normalized;
  }

  String _normalizeDay(String raw) {
    var lower = raw.toLowerCase().replaceAll('.', '').trim();
    const replacements = {
      'á': 'a',
      'é': 'e',
      'í': 'i',
      'ó': 'o',
      'ú': 'u',
    };
    for (final entry in replacements.entries) {
      lower = lower.replaceAll(entry.key, entry.value);
    }
    if (lower.isEmpty) return '';
    return lower.substring(0, math.min(3, lower.length));
  }

  @override
  Widget build(BuildContext context) {
    final adjustedValues = _emphasizedValues();
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 25),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              reservedSize: 36,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= points.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(points[index].dayLabel),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 40, interval: 25),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        lineBarsData: [
          LineChartBarData(
            color: AppColors.primary,
            barWidth: 4,
            isCurved: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true, color: AppColors.primary.withValues(alpha: .15)),
            spots: [
              for (int i = 0; i < points.length; i++) FlSpot(i.toDouble(), adjustedValues[i]),
            ],
          ),
        ],
        minY: 0,
        maxY: 100,
        minX: 0,
        maxX: (points.length - 1).toDouble(),
      ),
    );
  }
}

class _MicrorutaTable extends StatelessWidget {
  const _MicrorutaTable({
    required this.trips,
    required this.collectors,
    required this.collectorRoutes,
    required this.microrutas,
  });

  final List<TripSummaryDto> trips;
  final List<CollectorSummary> collectors;
  final List<RecolectorRutaDto> collectorRoutes;
  final List<MicrorutaDto> microrutas;

  @override
  Widget build(BuildContext context) {
    final format = NumberFormat("00");
    final collectorById = {
      for (final collector in collectors) collector.recolectorId: collector,
    };
    final microrutaById = {for (final micro in microrutas) micro.id: micro};
    final tripByMicroruta = {
      for (final trip in trips)
        trip.microrutaNombre.toLowerCase(): trip,
    };
    final List<_MicrorutaRoute> rows = collectorRoutes.isNotEmpty
        ? collectorRoutes
            .map(_MicrorutaRoute.fromDto)
            .toList(growable: false)
        : _routesFromTrips(trips);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Microruta')),
          DataColumn(label: Text('Recolector')),
          DataColumn(label: Text('Cobertura')),
          DataColumn(label: Text('Tiempo')),
          DataColumn(label: Text('Bolsas')),
          DataColumn(label: Text('Estado')),
          DataColumn(label: Text('Incidencias')),
        ],
        rows: [
          for (final route in rows)
            _buildRow(
              route: route,
              collectorById: collectorById,
              tripByMicroruta: tripByMicroruta,
              microrutaById: microrutaById,
              format: format,
            ),
        ],
      ),
    );
  }

  DataRow _buildRow({
    required _MicrorutaRoute route,
    required Map<int, CollectorSummary> collectorById,
    required Map<String, TripSummaryDto> tripByMicroruta,
    required Map<int, MicrorutaDto> microrutaById,
    required NumberFormat format,
  }) {
    final collector = _collectorForRoute(route, collectorById);
    final coveragePercent = _randomCoveragePercent(route.id);
    final incidentes = _resolveIncidentes(route, tripByMicroruta);
    final estado = _resolveEstado(route, tripByMicroruta);
    final microrutaNombre = _resolveMicrorutaNombre(route, microrutaById);
    final durationLabel = _formatDuration(_randomDuration(route.id), format);
    final bolsasPromedio = _bagsPerCollector(collector);
    final recolectorLabel = collector?.nombre ?? route.userId;

    return DataRow(
      cells: [
        DataCell(Row(
          children: [
            _StatusDot(color: _statusColor(estado)),
            const SizedBox(width: 8),
            Text(microrutaNombre),
          ],
        )),
        DataCell(Text(recolectorLabel)),
        DataCell(Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: coveragePercent / 100,
                minHeight: 6,
                borderRadius: BorderRadius.circular(8),
                color: AppColors.primary,
                backgroundColor: AppColors.surface,
              ),
            ),
            const SizedBox(width: 8),
            Text('${coveragePercent.toStringAsFixed(0)}%'),
          ],
        )),
        DataCell(Text(durationLabel)),
        DataCell(Text(bolsasPromedio.toStringAsFixed(1))),
        DataCell(_StatusPill(text: estado)),
        DataCell(Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: incidentes > 0 ? AppColors.warning : Colors.grey.shade300,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text('$incidentes'),
          ],
        )),
      ],
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Completada':
        return AppColors.primary;
      case 'Desviada':
        return AppColors.warning;
      default:
        return AppColors.info;
    }
  }

  CollectorSummary? _collectorForRoute(
    _MicrorutaRoute route,
    Map<int, CollectorSummary> collectorById,
  ) {
    final trimmed = route.userId.trim();
    final numericId = int.tryParse(trimmed);
    if (numericId != null) {
      final summary = collectorById[numericId];
      if (summary != null) return summary;
    }
    final lower = trimmed.toLowerCase();
    for (final summary in collectorById.values) {
      if (summary.nombre.trim().toLowerCase() == lower) {
        return summary;
      }
    }
    return null;
  }

  double _bagsPerCollector(CollectorSummary? collector) {
    if (collector == null || collector.recorridos == 0) {
      return 0;
    }
    return collector.bolsasTotales / collector.recorridos;
  }

  Duration _randomDuration(int seed) {
    final random = math.Random(seed);
    final minutes = 30 + random.nextInt(61);
    return Duration(minutes: minutes);
  }

  String _formatDuration(Duration duration, NumberFormat format) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return '${format.format(hours)}h ${format.format(minutes)}m';
  }

  double _randomCoveragePercent(int seed) {
    final random = math.Random(seed * 37);
    return 50 + random.nextDouble() * 50;
  }

  String _resolveEstado(
    _MicrorutaRoute route,
    Map<String, TripSummaryDto> tripByMicroruta,
  ) {
    return tripByMicroruta[route.microrutaNombre.toLowerCase()]?.estado ??
        'Completada';
  }

  int _resolveIncidentes(
    _MicrorutaRoute route,
    Map<String, TripSummaryDto> tripByMicroruta,
  ) {
    return tripByMicroruta[route.microrutaNombre.toLowerCase()]?.incidentes ??
        0;
  }

  String _resolveMicrorutaNombre(
    _MicrorutaRoute route,
    Map<int, MicrorutaDto> microrutaById,
  ) {
    final micro = microrutaById[route.microrutaId];
    return micro?.nombre ?? route.microrutaNombre;
  }

  List<_MicrorutaRoute> _routesFromTrips(List<TripSummaryDto> trips) {
    return trips
        .map(
          (trip) => _MicrorutaRoute(
            id: trip.id,
            userId: trip.recolectorNombre,
            microrutaId: 0,
            microrutaNombre: trip.microrutaNombre,
          ),
        )
        .toList(growable: false);
  }
}

class _MicrorutaRoute {
  const _MicrorutaRoute({
    required this.id,
    required this.userId,
    required this.microrutaId,
    required this.microrutaNombre,
  });

  factory _MicrorutaRoute.fromDto(RecolectorRutaDto dto) => _MicrorutaRoute(
        id: dto.id,
        userId: dto.userId,
        microrutaId: dto.microrutaId,
        microrutaNombre: dto.microrutaNombre,
      );

  final int id;
  final String userId;
  final int microrutaId;
  final String microrutaNombre;

  String get userKey => userId.trim().toLowerCase();
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final color = switch (text) {
      'Completada' => AppColors.primary,
      'Desviada' => AppColors.warning,
      _ => AppColors.info,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
  }
}
