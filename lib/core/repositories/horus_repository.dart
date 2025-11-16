import 'package:flutter/material.dart';

import '../models/models.dart';

abstract class HorusRepository {
  Future<DashboardMetrics> fetchDashboardMetrics(DateTime date);
  Future<List<MacrorutaDto>> getMacrorutas();
  Future<List<MicrorutaDto>> getMicrorutas({int? macrorutaId});
  Future<List<TripSummaryDto>> getTrips({int? macrorutaId, DateTime? date});
  Future<List<TripSummaryDto>> getActiveTrips({int? macrorutaId});
  Future<List<RecolectorStatusDto>> getCollectorStatus({int? macrorutaId});
  Future<List<RecolectorRutaDto>> getCollectorRoutes({String? userId});
  Future<RecolectorRutaDto> createCollectorRoute(
    CreateRecolectorRutaDto dto,
  );
  Future<RecolectorRutaDto> updateCollectorRoute(
    int id,
    CreateRecolectorRutaDto dto,
  );
  Future<void> deleteCollectorRoute(int id);
  Future<List<CollectorSummary>> getCollectors({
    String? search,
    String? estado,
  });
  Future<List<ComplianceTrendPoint>> getComplianceTrend();
  Future<List<MacroRouteBags>> getMacroRouteBags();
  Future<void> updateMicrorutaGeometry({
    required int microrutaId,
    required List<MicrorutaPointDto> points,
  });
  Future<Trip> startTrip(StartTripDto dto);
  Future<void> sendPosition(PositionUpdateDto dto);
  Future<void> finishTrip(FinishTripDto dto);
  Future<void> sendBagEvent(BagEventDto dto);
  Future<void> sendIncident(IncidentDto dto);
  Future<List<PositionSample>> getTripPositions(int tripId);
  Future<RecalculateRouteResponseDto> recalculateRoute({
    required double currentLatitude,
    required double currentLongitude,
    required int microrutaId,
  });
}

@immutable
class HorusRepositoryScope extends InheritedWidget {
  const HorusRepositoryScope({
    required this.repository,
    required super.child,
    super.key,
  });

  final HorusRepository repository;

  static HorusRepository of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<HorusRepositoryScope>();
    assert(scope != null, 'HorusRepositoryScope not found in context');
    return scope!.repository;
  }

  @override
  bool updateShouldNotify(covariant HorusRepositoryScope oldWidget) =>
      repository != oldWidget.repository;
}
