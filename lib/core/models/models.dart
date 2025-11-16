import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/microruta_point_dto.dart';
export '../../models/microruta_point_dto.dart';

class MacrorutaDto {
  const MacrorutaDto({
    required this.id,
    required this.nombre,
    required this.colorHex,
    required this.microrutasCount,
  });

  factory MacrorutaDto.fromJson(Map<String, dynamic> json) => MacrorutaDto(
    id: json['id'] as int,
    nombre: json['nombre'] as String? ?? 'Macroruta',
    colorHex: json['colorHex'] as String? ?? '#2DA754',
    microrutasCount: json['microrutasCount'] as int? ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'colorHex': colorHex,
    'microrutasCount': microrutasCount,
  };

  final int id;
  final String nombre;
  final String colorHex;
  final int microrutasCount;

  Color get color => Color(int.parse(colorHex.replaceFirst('#', '0xff')));
}

class MicrorutaDto {
  const MicrorutaDto({
    required this.id,
    required this.nombre,
    required this.macrorutaId,
    required this.macrorutaNombre,
    required this.points,
  });

  factory MicrorutaDto.fromJson(Map<String, dynamic> json) => MicrorutaDto(
    id: json['id'] as int,
    nombre: json['nombre'] as String? ?? 'MR',
    macrorutaId: json['macrorutaId'] as int,
    macrorutaNombre: json['macrorutaNombre'] as String? ?? 'Macroruta',
    points:
        (json['points'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(MicrorutaPointDto.fromJson)
            .toList(growable: false) ??
        const [],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'macrorutaId': macrorutaId,
    'macrorutaNombre': macrorutaNombre,
    'points': points.map((point) => point.toJson()).toList(),
  };

  final int id;
  final String nombre;
  final int macrorutaId;
  final String macrorutaNombre;
  final List<MicrorutaPointDto> points;
}

class RecolectorRutaDto {
  const RecolectorRutaDto({
    required this.id,
    required this.userId,
    required this.macrorutaId,
    required this.macrorutaNombre,
    required this.microrutaId,
    required this.microrutaNombre,
  });

  factory RecolectorRutaDto.fromJson(Map<String, dynamic> json) =>
      RecolectorRutaDto(
        id: json['id'] as int? ?? 0,
        userId: json['userId'] as String? ?? '',
        macrorutaId: json['macrorutaId'] as int? ?? 0,
        macrorutaNombre: json['macrorutaNombre'] as String? ?? 'Macroruta',
        microrutaId: json['microrutaId'] as int? ?? 0,
        microrutaNombre: json['microrutaNombre'] as String? ?? 'Microruta',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'macrorutaId': macrorutaId,
        'macrorutaNombre': macrorutaNombre,
        'microrutaId': microrutaId,
        'microrutaNombre': microrutaNombre,
      };

  final int id;
  final String userId;
  final int macrorutaId;
  final String macrorutaNombre;
  final int microrutaId;
  final String microrutaNombre;
}

class CreateRecolectorRutaDto {
  const CreateRecolectorRutaDto({
    required this.userId,
    required this.macrorutaId,
    required this.microrutaId,
  });

  factory CreateRecolectorRutaDto.fromJson(Map<String, dynamic> json) =>
      CreateRecolectorRutaDto(
        userId: json['userId'] as String? ?? '',
        macrorutaId: json['macrorutaId'] as int? ?? 0,
        microrutaId: json['microrutaId'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'macrorutaId': macrorutaId,
        'microrutaId': microrutaId,
      };

  final String userId;
  final int macrorutaId;
  final int microrutaId;
}

class TripSummaryDto {
  const TripSummaryDto({
    required this.id,
    required this.recolectorNombre,
    required this.microrutaNombre,
    required this.inicio,
    this.fin,
    required this.bolsas,
    required this.coberturaPorciento,
    required this.distanciaMetros,
    required this.estado,
    required this.incidentes,
  });

  factory TripSummaryDto.fromJson(Map<String, dynamic> json) => TripSummaryDto(
    id: json['id'] as int,
    recolectorNombre: json['recolectorNombre'] as String? ?? 'Desconocido',
    microrutaNombre: json['microrutaNombre'] as String? ?? 'MR',
    inicio: DateTime.parse(json['inicio'] as String),
    fin: json['fin'] != null ? DateTime.tryParse(json['fin'] as String) : null,
    bolsas: json['bolsas'] as int? ?? 0,
    coberturaPorciento: (json['coberturaPorciento'] as num?)?.toDouble() ?? 0,
    distanciaMetros: (json['distanciaMetros'] as num?)?.toDouble() ?? 0,
    estado: json['estado'] as String? ?? 'En progreso',
    incidentes: json['incidentes'] as int? ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'recolectorNombre': recolectorNombre,
    'microrutaNombre': microrutaNombre,
    'inicio': inicio.toIso8601String(),
    'fin': fin?.toIso8601String(),
    'bolsas': bolsas,
    'coberturaPorciento': coberturaPorciento,
    'distanciaMetros': distanciaMetros,
    'estado': estado,
    'incidentes': incidentes,
  };

  final int id;
  final String recolectorNombre;
  final String microrutaNombre;
  final DateTime inicio;
  final DateTime? fin;
  final int bolsas;
  final double coberturaPorciento;
  final double distanciaMetros;
  final String estado;
  final int incidentes;
}

class Trip {
  const Trip({
    required this.id,
    required this.recolectorId,
    required this.microrutaId,
    required this.estado,
    required this.inicio,
    this.fin,
    required this.bolsas,
    required this.coberturaPorciento,
    this.samples = const [],
  });

  factory Trip.fromJson(Map<String, dynamic> json) => Trip(
    id: json['id'] as int,
    recolectorId: json['recolectorId'] as int,
    microrutaId: json['microrutaId'] as int,
    estado: json['estado'] as String? ?? 'En progreso',
    inicio: DateTime.parse(json['inicio'] as String),
    fin: json['fin'] != null ? DateTime.tryParse(json['fin'] as String) : null,
    bolsas: json['bolsas'] as int? ?? 0,
    coberturaPorciento: (json['coberturaPorciento'] as num?)?.toDouble() ?? 0,
    samples:
        (json['samples'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(PositionSample.fromJson)
            .toList(growable: false) ??
        const [],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'recolectorId': recolectorId,
    'microrutaId': microrutaId,
    'estado': estado,
    'inicio': inicio.toIso8601String(),
    'fin': fin?.toIso8601String(),
    'bolsas': bolsas,
    'coberturaPorciento': coberturaPorciento,
    'samples': samples.map((sample) => sample.toJson()).toList(),
  };

  final int id;
  final int recolectorId;
  final int microrutaId;
  final String estado;
  final DateTime inicio;
  final DateTime? fin;
  final int bolsas;
  final double coberturaPorciento;
  final List<PositionSample> samples;
}

class PositionSample {
  const PositionSample({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.speed,
  });

  factory PositionSample.fromJson(Map<String, dynamic> json) => PositionSample(
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    timestamp: DateTime.parse(json['timestamp'] as String),
    speed: (json['speed'] as num?)?.toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'timestamp': timestamp.toIso8601String(),
    if (speed != null) 'speed': speed,
  };

  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double? speed;
}

class RecolectorStatusDto {
  const RecolectorStatusDto({
    required this.recolectorId,
    required this.recolectorNombre,
    required this.microrutaNombre,
    required this.estado,
    required this.ultimaActualizacion,
    required this.bolsas,
    required this.coberturaPorciento,
    this.latitude,
    this.longitude,
  });

  factory RecolectorStatusDto.fromJson(Map<String, dynamic> json) =>
      RecolectorStatusDto(
        recolectorId: json['recolectorId'] as int,
        recolectorNombre: json['recolectorNombre'] as String? ?? 'Recolector',
        microrutaNombre: json['microrutaNombre'] as String? ?? 'MR',
        estado: json['estado'] as String? ?? 'En ruta',
        ultimaActualizacion: json['ultimaActualizacion'] != null
            ? DateTime.tryParse(json['ultimaActualizacion'] as String)
            : null,
        bolsas: json['bolsas'] as int? ?? 0,
        coberturaPorciento:
            (json['coberturaPorciento'] as num?)?.toDouble() ?? 0,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
    'recolectorId': recolectorId,
    'recolectorNombre': recolectorNombre,
    'microrutaNombre': microrutaNombre,
    'estado': estado,
    'ultimaActualizacion': ultimaActualizacion?.toIso8601String(),
    'bolsas': bolsas,
    'coberturaPorciento': coberturaPorciento,
    'latitude': latitude,
    'longitude': longitude,
  };

  final int recolectorId;
  final String recolectorNombre;
  final String microrutaNombre;
  final String estado;
  final DateTime? ultimaActualizacion;
  final int bolsas;
  final double coberturaPorciento;
  final double? latitude;
  final double? longitude;
}

class RecolectorDto {
  const RecolectorDto({
    required this.id,
    required this.nombre,
    required this.activo,
  });

  factory RecolectorDto.fromJson(Map<String, dynamic> json) => RecolectorDto(
    id: json['id'] as int,
    nombre: json['nombre'] as String? ?? 'Recolector',
    activo: json['activo'] as bool? ?? true,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'activo': activo,
  };

  final int id;
  final String nombre;
  final bool activo;
}

class RecolectorStatsDto {
  const RecolectorStatsDto({
    required this.id,
    required this.recolectorId,
    required this.recolectorNombre,
    required this.bolsasTotales,
    required this.coberturaPromedio,
    required this.cantidadRecorridos,
  });

  factory RecolectorStatsDto.fromJson(Map<String, dynamic> json) =>
      RecolectorStatsDto(
        id: json['id'] as int? ?? 0,
        recolectorId: json['recolectorId'] as int? ?? 0,
        recolectorNombre: json['recolectorNombre'] as String? ?? 'Recolector',
        bolsasTotales: json['bolsasTotales'] as int? ?? 0,
        coberturaPromedio:
            (json['coberturaPromedio'] as num?)?.toDouble() ?? 0.0,
        cantidadRecorridos: json['cantidadRecorridos'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'recolectorId': recolectorId,
        'recolectorNombre': recolectorNombre,
        'bolsasTotales': bolsasTotales,
        'coberturaPromedio': coberturaPromedio,
        'cantidadRecorridos': cantidadRecorridos,
      };

  final int id;
  final int recolectorId;
  final String recolectorNombre;
  final int bolsasTotales;
  final double coberturaPromedio;
  final int cantidadRecorridos;
}

DashboardMetrics dashboardMetricsFromJson(String source) {
  final map = jsonDecode(source) as Map<String, dynamic>;
  return DashboardMetrics.fromJson(map);
}

class DashboardMetrics {
  const DashboardMetrics({
    required this.microrutasActivas,
    required this.totalMicrorutas,
    required this.coberturaPromedio,
    required this.totalBolsas,
    required this.incidentesActivos,
  });

  factory DashboardMetrics.fromJson(Map<String, dynamic> json) =>
      DashboardMetrics(
        microrutasActivas: json['microrutasActivas'] as int? ?? 0,
        totalMicrorutas: json['totalMicrorutas'] as int? ?? 0,
        coberturaPromedio: (json['coberturaPromedio'] as num?)?.toDouble() ?? 0,
        totalBolsas: (json['totalBolsas'] as num?)?.toDouble() ?? 0,
        incidentesActivos: json['incidentesActivos'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
    'microrutasActivas': microrutasActivas,
    'totalMicrorutas': totalMicrorutas,
    'coberturaPromedio': coberturaPromedio,
    'totalBolsas': totalBolsas,
    'incidentesActivos': incidentesActivos,
  };

  final int microrutasActivas;
  final int totalMicrorutas;
  final double coberturaPromedio;
  final double totalBolsas;
  final int incidentesActivos;
}

class CollectorSummary {
  const CollectorSummary({
    required this.recolectorId,
    required this.nombre,
    required this.macroruta,
    required this.bolsasTotales,
    required this.coberturaPromedio,
    required this.recorridos,
    required this.ultimaActividad,
    required this.estado,
  });

  factory CollectorSummary.fromStats(RecolectorStatsDto dto) {
    return CollectorSummary(
      recolectorId: dto.recolectorId,
      nombre: dto.recolectorNombre,
      macroruta: 'Sin ruta',
      bolsasTotales: dto.bolsasTotales,
      coberturaPromedio: dto.coberturaPromedio,
      recorridos: dto.cantidadRecorridos,
      ultimaActividad: DateTime.now(),
      estado: 'Activo',
    );
  }

  final int recolectorId;
  final String nombre;
  final String macroruta;
  final int bolsasTotales;
  final double coberturaPromedio;
  final int recorridos;
  final DateTime ultimaActividad;
  final String estado;
}

class ComplianceTrendPoint {
  const ComplianceTrendPoint({required this.dayLabel, required this.value});

  final String dayLabel;
  final double value;
}

class MacroRouteBags {
  const MacroRouteBags({
    required this.nombre,
    required this.cantidad,
    required this.color,
  });

  final String nombre;
  final int cantidad;
  final Color color;
}

class StartTripDto {
  const StartTripDto({
    required this.recolectorId,
    required this.microrutaId,
    required this.inicio,
  });

  factory StartTripDto.fromJson(Map<String, dynamic> json) => StartTripDto(
        recolectorId: json['recolectorId'] as int,
        microrutaId: json['microrutaId'] as int,
        inicio: DateTime.parse(json['inicio'] as String),
      );

  Map<String, dynamic> toJson() => {
    'recolectorId': recolectorId,
    'microrutaId': microrutaId,
    'inicio': inicio.toIso8601String(),
  };

  final int recolectorId;
  final int microrutaId;
  final DateTime inicio;
}

class PositionUpdateDto {
  const PositionUpdateDto({
    required this.tripId,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.speed,
  });

  factory PositionUpdateDto.fromJson(Map<String, dynamic> json) => PositionUpdateDto(
        tripId: json['tripId'] as int,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        timestamp: DateTime.parse(json['timestamp'] as String),
        speed: (json['speed'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
    'tripId': tripId,
    'latitude': latitude,
    'longitude': longitude,
    'timestamp': timestamp.toIso8601String(),
    if (speed != null) 'speed': speed,
  };

  final int tripId;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double? speed;
}

class FinishTripDto {
  const FinishTripDto({
    required this.tripId,
    required this.fin,
  });

  factory FinishTripDto.fromJson(Map<String, dynamic> json) => FinishTripDto(
        tripId: json['tripId'] as int,
        fin: DateTime.parse(json['fin'] as String),
      );

  Map<String, dynamic> toJson() => {
        'tripId': tripId,
        'fin': fin.toIso8601String(),
      };

  final int tripId;
  final DateTime fin;
}

class BagEventDto {
  const BagEventDto({
    required this.tripId,
    required this.microrutaId,
    required this.cantidad,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'tripId': tripId,
    'microrutaId': microrutaId,
    'cantidad': cantidad,
    'timestamp': timestamp.toIso8601String(),
  };

  final int tripId;
  final int microrutaId;
  final int cantidad;
  final DateTime timestamp;
}

class IncidentDto {
  const IncidentDto({
    required this.tripId,
    required this.tipo,
    required this.descripcion,
    required this.timestamp,
    this.latitude,
    this.longitude,
  });

  Map<String, dynamic> toJson() => {
    'tripId': tripId,
    'tipo': tipo,
    'descripcion': descripcion,
    'timestamp': timestamp.toIso8601String(),
    if (latitude != null) 'latitude': latitude,
    if (longitude != null) 'longitude': longitude,
  };

  final int tripId;
  final String tipo;
  final String descripcion;
  final DateTime timestamp;
  final double? latitude;
  final double? longitude;
}

class RecalculateRouteRequestDto {
  const RecalculateRouteRequestDto({
    required this.currentLatitude,
    required this.currentLongitude,
    required this.microrutaId,
  });

  Map<String, dynamic> toJson() => {
        'currentLatitude': currentLatitude,
        'currentLongitude': currentLongitude,
        'microrutaId': microrutaId,
      };

  final double currentLatitude;
  final double currentLongitude;
  final int microrutaId;
}

class RoutePathPointDto {
  const RoutePathPointDto({
    required this.latitude,
    required this.longitude,
  });

  factory RoutePathPointDto.fromJson(Map<String, dynamic> json) =>
      RoutePathPointDto(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
      };

  final double latitude;
  final double longitude;
}

class RecalculateRouteResponseDto {
  const RecalculateRouteResponseDto({
    required this.path,
  });

  factory RecalculateRouteResponseDto.fromJson(Map<String, dynamic> json) =>
      RecalculateRouteResponseDto(
        path: (json['path'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .map(RoutePathPointDto.fromJson)
                .toList(growable: false) ??
            const [],
      );

  Map<String, dynamic> toJson() => {
        'path': path.map((point) => point.toJson()).toList(growable: false),
      };

  final List<RoutePathPointDto> path;
}

double haversineDistance({
  required double lat1,
  required double lon1,
  required double lat2,
  required double lon2,
}) {
  const earthRadiusKm = 6371.0;
  final dLat = _toRadians(lat2 - lat1);
  final dLon = _toRadians(lon2 - lon1);
  final a =
      (sin(dLat / 2) * sin(dLat / 2)) +
          cos(_toRadians(lat1)) *
              cos(_toRadians(lat2)) *
              sin(dLon / 2) *
              sin(dLon / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return earthRadiusKm * c;
}

double _toRadians(double degrees) => degrees * pi / 180;
