import 'dart:math';

import 'package:flutter/material.dart';

import '../models/models.dart';
import 'horus_repository.dart';

class MockHorusRepository implements HorusRepository {
  MockHorusRepository();

  final List<MicrorutaDto> _microrutas = [
    MicrorutaDto(
      id: 1,
      nombre: 'MR-01',
      macrorutaId: 1,
      macrorutaNombre: 'Verde',
      points: const [
        MicrorutaPointDto(latitude: -17.80, longitude: -63.18),
        MicrorutaPointDto(latitude: -17.79, longitude: -63.17),
      ],
    ),
    MicrorutaDto(
      id: 2,
      nombre: 'MR-02',
      macrorutaId: 2,
      macrorutaNombre: 'Roja',
      points: const [
        MicrorutaPointDto(latitude: -17.82, longitude: -63.20),
        MicrorutaPointDto(latitude: -17.81, longitude: -63.19),
      ],
    ),
    MicrorutaDto(
      id: 3,
      nombre: 'MR-03',
      macrorutaId: 1,
      macrorutaNombre: 'Verde',
      points: const [
        MicrorutaPointDto(latitude: -17.78, longitude: -63.16),
        MicrorutaPointDto(latitude: -17.77, longitude: -63.15),
      ],
    ),
    MicrorutaDto(
      id: 4,
      nombre: 'MR-04',
      macrorutaId: 3,
      macrorutaNombre: 'Naranja',
      points: const [
        MicrorutaPointDto(latitude: -17.76, longitude: -63.14),
        MicrorutaPointDto(latitude: -17.75, longitude: -63.13),
      ],
    ),
    MicrorutaDto(
      id: 5,
      nombre: 'MR-05',
      macrorutaId: 4,
      macrorutaNombre: 'Lila',
      points: const [
        MicrorutaPointDto(latitude: -17.83, longitude: -63.22),
        MicrorutaPointDto(latitude: -17.82, longitude: -63.21),
      ],
    ),
    MicrorutaDto(
      id: 6,
      nombre: 'MR-06',
      macrorutaId: 1,
      macrorutaNombre: 'Verde',
      points: const [
        MicrorutaPointDto(latitude: -17.81, longitude: -63.18),
        MicrorutaPointDto(latitude: -17.80, longitude: -63.17),
      ],
    ),
  ];

  final List<RecolectorRutaDto> _collectorRoutes = [
    const RecolectorRutaDto(
      id: 1,
      userId: 'user-juan',
      macrorutaId: 1,
      macrorutaNombre: 'Verde',
      microrutaId: 1,
      microrutaNombre: 'MR-01',
    ),
    const RecolectorRutaDto(
      id: 2,
      userId: 'user-maria',
      macrorutaId: 2,
      macrorutaNombre: 'Roja',
      microrutaId: 2,
      microrutaNombre: 'MR-02',
    ),
    const RecolectorRutaDto(
      id: 3,
      userId: 'user-carlos',
      macrorutaId: 1,
      macrorutaNombre: 'Verde',
      microrutaId: 3,
      microrutaNombre: 'MR-03',
    ),
  ];

  final Map<int, Trip> _trips = {};
  final Map<int, List<PositionSample>> _tripPositions = {};
  int _tripSeed = 1000;

  @override
  Future<DashboardMetrics> fetchDashboardMetrics(DateTime date) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final coverageAvg = _collectorCoverageValues
            .reduce((value, element) => value + element) /
        _collectorCoverageValues.length;
    final perCollectorBags = List<double>.generate(
      _collectorTotalBags.length,
      (index) {
        final recorridos = _collectorRecorridos[index];
        if (recorridos == 0) return 0;
        return _collectorTotalBags[index] / recorridos;
      },
    );
    final avgDailyBags = perCollectorBags.isEmpty
      ? 0.0
        : perCollectorBags.reduce((a, b) => a + b) / perCollectorBags.length;
    return DashboardMetrics(
      microrutasActivas: 4,
      totalMicrorutas: 6,
      coberturaPromedio: coverageAvg,
      totalBolsas: avgDailyBags,
      incidentesActivos: 4,
    );
  }

  @override
  Future<List<MacrorutaDto>> getMacrorutas() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const [
      MacrorutaDto(
        id: 1,
        nombre: 'Verde',
        colorHex: '#2DA754',
        microrutasCount: 6,
      ),
      MacrorutaDto(
        id: 2,
        nombre: 'Roja',
        colorHex: '#E74C3C',
        microrutasCount: 4,
      ),
      MacrorutaDto(
        id: 3,
        nombre: 'Naranja',
        colorHex: '#F39C12',
        microrutasCount: 5,
      ),
      MacrorutaDto(
        id: 4,
        nombre: 'Lila',
        colorHex: '#B678F1',
        microrutasCount: 3,
      ),
    ];
  }

  @override
  Future<List<MicrorutaDto>> getMicrorutas({int? macrorutaId}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _microrutas
        .where((item) => macrorutaId == null || item.macrorutaId == macrorutaId)
        .toList(growable: false);
  }

  @override
  Future<List<TripSummaryDto>> getTrips({
    int? macrorutaId,
    DateTime? date,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return List.generate(6, (index) {
      final microrutaId = index + 1;
      return TripSummaryDto(
        id: microrutaId,
        recolectorNombre: _collectorNames[index],
        microrutaNombre: 'MR-0$microrutaId',
        inicio: DateTime.now().subtract(Duration(hours: index + 1)),
        fin: null,
        bolsas: [24, 18, 12, 32, 8, 28][index],
        coberturaPorciento: [85, 72, 45, 100, 30, 90][index].toDouble(),
        distanciaMetros: 12000,
        estado: _states[index],
        incidentes: [0, 1, 2, 0, 1, 0][index],
      );
    });
  }

  @override
  Future<List<TripSummaryDto>> getActiveTrips({int? macrorutaId}) =>
      getTrips(macrorutaId: macrorutaId);

  @override
  Future<List<RecolectorStatusDto>> getCollectorStatus({
    int? macrorutaId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 350));
    return List.generate(6, (index) {
      return RecolectorStatusDto(
        recolectorId: index + 1,
        recolectorNombre: _collectorNames[index],
        microrutaNombre: 'MR-0${index + 1}',
        estado: _statusLabels[index],
        ultimaActualizacion: DateTime.now().subtract(
          Duration(minutes: index * 2),
        ),
        bolsas: [24, 18, 12, 32, 8, 28][index],
        coberturaPorciento: [85, 72, 45, 100, 30, 90][index].toDouble(),
        latitude: -17.78 + index * 0.01,
        longitude: -63.18 + index * 0.01,
      );
    });
  }

  @override
  Future<List<CollectorSummary>> getCollectors({
    String? search,
    String? estado,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return List.generate(6, (index) {
      return CollectorSummary(
        recolectorId: index + 1,
        nombre: _collectorNames[index],
        macroruta: _routeColors[index],
        bolsasTotales: _collectorTotalBags[index],
        coberturaPromedio: _collectorCoverageValues[index].toDouble(),
        recorridos: _collectorRecorridos[index],
        ultimaActividad: DateTime.now().subtract(Duration(minutes: 5 * index)),
        estado: index % 3 == 0
            ? 'Activo'
            : index % 3 == 1
            ? 'En ruta'
            : 'Sin señal',
      );
    });
  }

  @override
  Future<List<ComplianceTrendPoint>> getComplianceTrend() async {
    await Future.delayed(const Duration(milliseconds: 250));
    const days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    return List.generate(days.length, (index) {
      final base = 75 + sin(index / 2) * 10;
      return ComplianceTrendPoint(dayLabel: days[index], value: base);
    });
  }

  @override
  Future<List<MacroRouteBags>> getMacroRouteBags() async {
    await Future.delayed(const Duration(milliseconds: 250));
    return const [
      MacroRouteBags(nombre: 'Verde', cantidad: 34, color: Color(0xFF2DA754)),
      MacroRouteBags(nombre: 'Roja', cantidad: 45, color: Color(0xFFE74C3C)),
      MacroRouteBags(nombre: 'Naranja', cantidad: 30, color: Color(0xFFF39C12)),
      MacroRouteBags(nombre: 'Lila', cantidad: 8, color: Color(0xFFB678F1)),
    ];
  }

  @override
  Future<void> updateMicrorutaGeometry({
    required int microrutaId,
    required List<MicrorutaPointDto> points,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _microrutas.indexWhere((route) => route.id == microrutaId);
    if (index == -1) return;
    final route = _microrutas[index];
    _microrutas[index] = MicrorutaDto(
      id: route.id,
      nombre: route.nombre,
      macrorutaId: route.macrorutaId,
      macrorutaNombre: route.macrorutaNombre,
      points: points,
    );
  }

  @override
  Future<List<RecolectorRutaDto>> getCollectorRoutes({String? userId}) async {
    await Future.delayed(const Duration(milliseconds: 250));
    if (userId == null || userId.trim().isEmpty) {
      return List<RecolectorRutaDto>.from(_collectorRoutes);
    }
    final normalized = userId.trim().toLowerCase();
    return _collectorRoutes
        .where((route) => route.userId.toLowerCase() == normalized)
        .toList(growable: false);
  }

  @override
  Future<RecolectorRutaDto> createCollectorRoute(
    CreateRecolectorRutaDto dto,
  ) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final nextId = _collectorRoutes.isEmpty
        ? 1
        : _collectorRoutes.map((route) => route.id).reduce(max) + 1;
    final created = _buildRouteFromDto(id: nextId, dto: dto);
    _collectorRoutes.add(created);
    return created;
  }

  @override
  Future<RecolectorRutaDto> updateCollectorRoute(
    int id,
    CreateRecolectorRutaDto dto,
  ) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final index = _collectorRoutes.indexWhere((route) => route.id == id);
    if (index == -1) {
      throw StateError('Collector route $id not found');
    }
    final updated = _buildRouteFromDto(id: id, dto: dto);
    _collectorRoutes[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteCollectorRoute(int id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _collectorRoutes.removeWhere((route) => route.id == id);
  }

  @override
  Future<Trip> startTrip(StartTripDto dto) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final tripId = _tripSeed++;
    final trip = Trip(
      id: tripId,
      recolectorId: dto.recolectorId,
      microrutaId: dto.microrutaId,
      estado: 'En progreso',
      inicio: dto.inicio,
      bolsas: 0,
      coberturaPorciento: 0,
      samples: const [],
    );
    _trips[tripId] = trip;
    _tripPositions[tripId] = [];
    return trip;
  }

  @override
  Future<void> sendPosition(PositionUpdateDto dto) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final positions = _tripPositions[dto.tripId];
    if (positions == null) return;
    positions.add(
      PositionSample(
        latitude: dto.latitude,
        longitude: dto.longitude,
        timestamp: dto.timestamp,
        speed: dto.speed,
      ),
    );
  }

  @override
  Future<void> finishTrip(FinishTripDto dto) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final trip = _trips[dto.tripId];
    if (trip == null) return;
    _trips[dto.tripId] = Trip(
      id: trip.id,
      recolectorId: trip.recolectorId,
      microrutaId: trip.microrutaId,
      estado: 'Finalizado',
      inicio: trip.inicio,
      fin: dto.fin,
      bolsas: trip.bolsas,
      coberturaPorciento: trip.coberturaPorciento,
      samples: _tripPositions[dto.tripId] ?? const [],
    );
  }

  @override
  Future<void> sendBagEvent(BagEventDto dto) async {
    await Future.delayed(const Duration(milliseconds: 150));
  }

  @override
  Future<void> sendIncident(IncidentDto dto) async {
    await Future.delayed(const Duration(milliseconds: 150));
  }

  @override
  Future<List<PositionSample>> getTripPositions(int tripId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return List<PositionSample>.from(_tripPositions[tripId] ?? const []);
  }

  @override
  Future<RecalculateRouteResponseDto> recalculateRoute({
    required double currentLatitude,
    required double currentLongitude,
    required int microrutaId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final route = _microrutas.firstWhere(
      (item) => item.id == microrutaId,
      orElse: () => _microrutas.first,
    );
    final path = [
      RoutePathPointDto(latitude: currentLatitude, longitude: currentLongitude),
      ...route.points.map(
        (point) => RoutePathPointDto(
          latitude: point.latitude,
          longitude: point.longitude,
        ),
      ),
    ].toList(growable: false);
    return RecalculateRouteResponseDto(path: path);
  }

  RecolectorRutaDto _buildRouteFromDto({
    required int id,
    required CreateRecolectorRutaDto dto,
  }) {
    final micro = _microrutas.firstWhere(
      (route) => route.id == dto.microrutaId,
      orElse: () => _microrutas.first,
    );
    final macrorutaName = _resolveMacrorutaName(dto.macrorutaId);
    return RecolectorRutaDto(
      id: id,
      userId: dto.userId,
      macrorutaId: dto.macrorutaId,
      macrorutaNombre: macrorutaName,
      microrutaId: dto.microrutaId,
      microrutaNombre: micro.nombre,
    );
  }

  String _resolveMacrorutaName(int macrorutaId) {
    for (final route in _microrutas) {
      if (route.macrorutaId == macrorutaId) {
        return route.macrorutaNombre;
      }
    }
    return 'Macroruta $macrorutaId';
  }
}

const _collectorNames = [
  'Juan Pérez',
  'María García',
  'Carlos Mendoza',
  'Ana Rodríguez',
  'Pedro Sánchez',
  'Laura Fernández',
];

const _states = [
  'En progreso',
  'En progreso',
  'Desviada',
  'Completada',
  'En progreso',
  'En progreso',
];

const _statusLabels = [
  'En ruta',
  'En ruta',
  'Fuera de ruta',
  'En ruta',
  'Sin señal',
  'En ruta',
];

const _routeColors = ['Verde', 'Roja', 'Verde', 'Naranja', 'Lila', 'Verde'];

const _collectorTotalBags = [456, 398, 412, 523, 275, 310];
const _collectorCoverageValues = [87, 82, 79, 92, 68, 75];
const _collectorRecorridos = [30, 28, 22, 25, 18, 21];
