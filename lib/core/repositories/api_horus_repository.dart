import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../config/app_config.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import 'horus_repository.dart';

class ApiHorusRepository implements HorusRepository {
  ApiHorusRepository({
    ApiService? apiService,
    String? baseUrl,
    http.Client? httpClient,
  }) : _api =
           apiService ??
           ApiService(
             baseUrl: baseUrl ?? AppConfig.instance.normalizedBackendBaseUrl,
             httpClient: httpClient,
           );

  final ApiService _api;

  Future<List<T>> _getList<T>(
    String path,
    T Function(Map<String, dynamic>) parser, {
    Map<String, dynamic>? query,
  }) async {
    final payload = await _api.get(path, queryParameters: query);
    if (payload == null) return const [];
    if (payload is List) {
      return payload
          .whereType<Map<String, dynamic>>()
          .map(parser)
          .toList(growable: false);
    }
    throw const FormatException(
      'Unexpected payload shape. Expected JSON array.',
    );
  }

  RecolectorRutaDto _parseCollectorRoutePayload(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      return RecolectorRutaDto.fromJson(payload);
    }
    throw const FormatException('Unexpected collector route payload.');
  }

  Future<List<TripSummaryDto>> _fetchTrips(
    String path, {
    int? macrorutaId,
    DateTime? date,
  }) {
    return _getList(
      path,
      TripSummaryDto.fromJson,
      query: {
        if (macrorutaId != null) 'macrorutaId': macrorutaId,
        if (date != null) 'date': date.toIso8601String(),
      },
    );
  }

  @override
  Future<List<MacrorutaDto>> getMacrorutas() async {
    return _getList('/api/Routes/macrorutas', MacrorutaDto.fromJson);
  }

  @override
  Future<List<MicrorutaDto>> getMicrorutas({int? macrorutaId}) async {
    return _getList(
      '/api/Routes/microrutas',
      MicrorutaDto.fromJson,
      query: {if (macrorutaId != null) 'macrorutaId': macrorutaId},
    );
  }

  @override
  Future<List<TripSummaryDto>> getTrips({int? macrorutaId, DateTime? date}) {
    return _fetchTrips('/api/Trips', macrorutaId: macrorutaId, date: date);
  }

  @override
  Future<List<TripSummaryDto>> getActiveTrips({int? macrorutaId}) {
    return _fetchTrips('/api/Trips/activos', macrorutaId: macrorutaId);
  }

  @override
  Future<List<RecolectorStatusDto>> getCollectorStatus({
    int? macrorutaId,
  }) async {
    return _getList(
      '/api/Recolectores/status',
      RecolectorStatusDto.fromJson,
      query: {if (macrorutaId != null) 'macrorutaId': macrorutaId},
    );
  }

  @override
  Future<List<RecolectorRutaDto>> getCollectorRoutes({String? userId}) {
    final path = (userId == null || userId.isEmpty)
        ? '/api/RecolectorRutas'
        : '/api/RecolectorRutas/by-user/${Uri.encodeComponent(userId)}';
    return _getList(path, RecolectorRutaDto.fromJson);
  }

  @override
  Future<RecolectorRutaDto> createCollectorRoute(
    CreateRecolectorRutaDto dto,
  ) async {
    final payload = await _api.post(
      '/api/RecolectorRutas',
      body: dto.toJson(),
    );
    return _parseCollectorRoutePayload(payload);
  }

  @override
  Future<RecolectorRutaDto> updateCollectorRoute(
    int id,
    CreateRecolectorRutaDto dto,
  ) async {
    final payload = await _api.put(
      '/api/RecolectorRutas/$id',
      body: dto.toJson(),
    );
    return _parseCollectorRoutePayload(payload);
  }

  @override
  Future<void> deleteCollectorRoute(int id) async {
    await _api.delete('/api/RecolectorRutas/$id');
  }

  Future<List<RecolectorStatsDto>> _getCollectorStats() async {
    try {
      return await _getList(
        '/api/RecolectorStats',
        RecolectorStatsDto.fromJson,
      );
    } on ApiException catch (error) {
      debugPrint('Collector stats endpoint unavailable: $error');
      return const [];
    }
  }

  @override
  Future<DashboardMetrics> fetchDashboardMetrics(DateTime date) async {
    final results = await Future.wait([
      getTrips(date: date),
      getCollectorStatus(),
      getMicrorutas(),
      _getCollectorStats(),
    ]);
    final trips = results[0] as List<TripSummaryDto>;
    final statuses = results[1] as List<RecolectorStatusDto>;
    final microrutas = results[2] as List<MicrorutaDto>;
    final stats = results[3] as List<RecolectorStatsDto>;

    final microrutasActivas = statuses.where((status) {
      final estado = status.estado.toLowerCase();
      return estado.contains('progreso') || estado.contains('ruta');
    }).length;

    final totalMicrorutas = microrutas.length;
    final coberturaPromedio = _resolveCoveragePromedio(trips, stats);
    final totalBolsas = _resolveAverageBolsas(stats, trips);
    final incidentesActivos = trips.fold<int>(
      0,
      (sum, trip) => sum + trip.incidentes,
    );

    return DashboardMetrics(
      microrutasActivas: microrutasActivas,
      totalMicrorutas: totalMicrorutas,
      coberturaPromedio: coberturaPromedio,
      totalBolsas: totalBolsas,
      incidentesActivos: incidentesActivos,
    );
  }

  double _resolveCoveragePromedio(
    List<TripSummaryDto> trips,
    List<RecolectorStatsDto> stats,
  ) {
    if (stats.isNotEmpty) {
      final total = stats.fold<double>(
        0,
        (sum, stat) => sum + stat.coberturaPromedio,
      );
      return total / stats.length;
    }

    if (trips.isEmpty) return 0.0;
    final total = trips.fold<double>(
      0,
      (sum, trip) => sum + trip.coberturaPorciento,
    );
    return total / trips.length;
  }

  double _resolveAverageBolsas(
    List<RecolectorStatsDto> stats,
    List<TripSummaryDto> fallbackTrips,
  ) {
    if (stats.isNotEmpty) {
      final samples = stats
          .where((stat) => stat.cantidadRecorridos > 0)
          .map((stat) => stat.bolsasTotales / stat.cantidadRecorridos)
          .toList(growable: false);
      if (samples.isNotEmpty) {
        final total = samples.fold<double>(0, (sum, value) => sum + value);
        return total / samples.length;
      }
      return 0;
    }

    return fallbackTrips
        .fold<int>(0, (sum, trip) => sum + trip.bolsas)
        .toDouble();
  }

  @override
  Future<List<ComplianceTrendPoint>> getComplianceTrend() async {
    final now = DateTime.now();
    late DateFormat formatter;
    try {
      formatter = DateFormat.E('es');
    } catch (_) {
      formatter = DateFormat.E();
    }
    final List<ComplianceTrendPoint> points = [];

    for (int offset = 6; offset >= 0; offset--) {
      final day = now.subtract(Duration(days: offset));
      final trips = await getTrips(date: day);
      final value = trips.isEmpty
          ? 0.0
          : trips
                    .map((trip) => trip.coberturaPorciento)
                    .reduce((a, b) => a + b) /
                trips.length;
      points.add(
        ComplianceTrendPoint(dayLabel: formatter.format(day), value: value),
      );
    }

    return points;
  }

  @override
  Future<List<MacroRouteBags>> getMacroRouteBags() async {
    final stats = await _getCollectorStats();
    if (stats.isNotEmpty) {
      final perCollectorTotals = stats
          .where((stat) => stat.cantidadRecorridos > 0)
          .map((stat) => stat.bolsasTotales / stat.cantidadRecorridos)
          .toList(growable: false);
      final totalValue = perCollectorTotals.fold<double>(0, (sum, value) => sum + value);
      if (totalValue > 0) {
        final macrorutas = await getMacrorutas();
        final reference = macrorutas.isNotEmpty ? macrorutas.first : null;
        return [
          MacroRouteBags(
            nombre: reference?.nombre ?? 'Macroruta Verde',
            cantidad: totalValue.round(),
            color: reference?.color ?? const Color(0xFF2DA754),
          ),
        ];
      }
    }

    final results = await Future.wait([
      getTrips(date: DateTime.now()),
      getMacrorutas(),
      getMicrorutas(),
    ]);
    final trips = results[0] as List<TripSummaryDto>;
    final macrorutas = results[1] as List<MacrorutaDto>;
    final microrutas = results[2] as List<MicrorutaDto>;

    final macroById = {for (final macro in macrorutas) macro.id: macro};
    final macroByMicroName = <String, MacrorutaDto>{
      for (final micro in microrutas)
        micro.nombre:
            macroById[micro.macrorutaId] ??
            MacrorutaDto(
              id: micro.macrorutaId,
              nombre: micro.macrorutaNombre,
              colorHex: '#2DA754',
              microrutasCount: 0,
            ),
    };

    final counts = <int, int>{};
    for (final trip in trips) {
      final macro = macroByMicroName[trip.microrutaNombre];
      if (macro == null) continue;
      counts[macro.id] = (counts[macro.id] ?? 0) + trip.bolsas;
    }

    if (counts.isEmpty) {
      return macrorutas
          .map(
            (macro) => MacroRouteBags(
              nombre: macro.nombre,
              cantidad: 0,
              color: macro.color,
            ),
          )
          .toList();
    }

    return counts.entries.map((entry) {
      final macro = macroById[entry.key];
      if (macro == null) {
        return MacroRouteBags(
          nombre: 'Macroruta ${entry.key}',
          cantidad: entry.value,
          color: const Color(0xFF2DA754),
        );
      }
      return MacroRouteBags(
        nombre: macro.nombre,
        cantidad: entry.value,
        color: macro.color,
      );
    }).toList();
  }

  @override
  Future<List<CollectorSummary>> getCollectors({
    String? search,
    String? estado,
  }) async {
    final stats = await _getCollectorStats();
    if (kDebugMode) {
      debugPrint('Collector stats fetched: ${stats.length}');
      final target = stats.where((stat) => stat.recolectorId == 1);
      if (target.isNotEmpty) {
        final sample = target.first;
        debugPrint(
          'Stats[recolectorId=1] bolsas=${sample.bolsasTotales}, '
          'cobertura=${sample.coberturaPromedio}, recorridos=${sample.cantidadRecorridos}',
        );
      } else {
        debugPrint('No stats entry found for recolectorId=1');
      }
    }
    final summaries = stats
        .map(CollectorSummary.fromStats)
        .toList(growable: false);

    Iterable<CollectorSummary> filtered = summaries;
    if (search != null && search.trim().isNotEmpty) {
      final query = search.toLowerCase();
      filtered = filtered.where(
        (summary) => summary.nombre.toLowerCase().contains(query),
      );
    }
    if (estado != null &&
        estado.trim().isNotEmpty &&
        estado.toLowerCase() != 'todos') {
      final target = estado.toLowerCase();
      filtered = filtered.where(
        (summary) => summary.estado.toLowerCase() == target,
      );
    }

    final sorted = filtered.toList()
      ..sort((a, b) => a.nombre.compareTo(b.nombre));
    if (kDebugMode && sorted.isNotEmpty) {
      CollectorSummary? ruddy;
      for (final summary in sorted) {
        if (summary.recolectorId == 1) {
          ruddy = summary;
          break;
        }
      }
      if (ruddy != null) {
        debugPrint(
          'CollectorSummary[1] -> bolsas=${ruddy.bolsasTotales}, '
          'cobertura=${ruddy.coberturaPromedio}, recorridos=${ruddy.recorridos}',
        );
      }
    }
    return sorted;
  }

  @override
  Future<void> updateMicrorutaGeometry({
    required int microrutaId,
    required List<MicrorutaPointDto> points,
  }) async {
    try {
      await _api.put(
        '/api/Routes/microrutas/$microrutaId/geometry',
        body: {
          'points': points.map((point) => point.toJson()).toList(),
        },
      );
    } on ApiException catch (error) {
      if (error.statusCode == 404) {
        debugPrint(
          'Microruta geometry endpoint not available on backend; '
          'keeping changes locally. (${error.uri})',
        );
        return;
      }
      rethrow;
    }
  }

  @override
  Future<Trip> startTrip(StartTripDto dto) async {
    final payload =
        await _api.post('/api/Tracking/start', body: dto.toJson())
            as Map<String, dynamic>;
    return Trip.fromJson(payload);
  }

  @override
  Future<void> sendPosition(PositionUpdateDto dto) async {
    await _api.post('/api/Tracking/position', body: dto.toJson());
  }

  @override
  Future<void> finishTrip(FinishTripDto dto) async {
    await _api.post('/api/Tracking/finish', body: dto.toJson());
  }

  @override
  Future<void> sendBagEvent(BagEventDto dto) async {
    await _api.post('/api/Tracking/bag', body: dto.toJson());
  }

  @override
  Future<void> sendIncident(IncidentDto dto) async {
    await _api.post('/api/Tracking/incident', body: dto.toJson());
  }

  @override
  Future<List<PositionSample>> getTripPositions(int tripId) async {
    final payload = await _api.get('/api/Trips/$tripId/positions');
    if (payload is List) {
      return payload
          .whereType<Map<String, dynamic>>()
          .map(PositionSample.fromJson)
          .toList(growable: false);
    }
    return const [];
  }

  @override
  Future<RecalculateRouteResponseDto> recalculateRoute({
    required double currentLatitude,
    required double currentLongitude,
    required int microrutaId,
  }) async {
    final payload = await _api.post(
      '/api/Routes/recalculate',
      body: {
        'currentLatitude': currentLatitude,
        'currentLongitude': currentLongitude,
        'microrutaId': microrutaId,
      },
    );
    if (payload is Map<String, dynamic>) {
      return RecalculateRouteResponseDto.fromJson(payload);
    }
    throw const FormatException('Invalid response for recalculate route');
  }
}

