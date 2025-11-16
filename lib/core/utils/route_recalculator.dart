import 'package:latlong2/latlong.dart';

import '../models/models.dart';

typedef _Segment = ({MicrorutaPointDto start, MicrorutaPointDto end});

/// Provides local route recalculation using only client-side microruta geometry.
class RouteRecalculator {
  const RouteRecalculator._();

  /// Returns a polyline starting at the closest point (vertex or segment)
  /// from [currentPosition] and following the remaining microruta points.
  static List<LatLng> recalculate({
    required LatLng currentPosition,
    required List<MicrorutaPointDto> originalPoints,
  }) {
    if (originalPoints.length < 2) {
      return originalPoints
          .map((point) => LatLng(point.latitude, point.longitude))
          .toList(growable: false);
    }

    final segments = _buildSegments(originalPoints);
    var bestDistance = double.infinity;
    LatLng? bestProjection;
    var bestIndex = 0;

    for (var i = 0; i < segments.length; i++) {
      final segment = segments[i];
      final projection = _projectOnSegment(
        start: segment.start,
        end: segment.end,
        point: currentPosition,
      );
      final distance = haversineDistance(
        lat1: projection.latitude,
        lon1: projection.longitude,
        lat2: currentPosition.latitude,
        lon2: currentPosition.longitude,
      );
      if (distance < bestDistance) {
        bestDistance = distance;
        bestProjection = projection;
        bestIndex = i + 1; // Continue from the end of this segment
      }
    }

    final polyline = <LatLng>[];
    if (bestProjection != null) {
      polyline.add(bestProjection);
    }
    polyline.addAll(
      originalPoints
          .skip(bestIndex)
          .where((point) => point.isBlocked != true)
          .map((point) => LatLng(point.latitude, point.longitude)),
    );
    return polyline;
  }

  static List<_Segment> _buildSegments(List<MicrorutaPointDto> points) {
    final list = <_Segment>[];
    for (var i = 0; i < points.length - 1; i++) {
      list.add((start: points[i], end: points[i + 1]));
    }
    return list;
  }

  static LatLng _projectOnSegment({
    required MicrorutaPointDto start,
    required MicrorutaPointDto end,
    required LatLng point,
  }) {
    final startLatLng = LatLng(start.latitude, start.longitude);
    final endLatLng = LatLng(end.latitude, end.longitude);

    final sx = startLatLng.longitude;
    final sy = startLatLng.latitude;
    final ex = endLatLng.longitude;
    final ey = endLatLng.latitude;
    final px = point.longitude;
    final py = point.latitude;

    final dx = ex - sx;
    final dy = ey - sy;
    if (dx == 0 && dy == 0) {
      return startLatLng;
    }

    final t = ((px - sx) * dx + (py - sy) * dy) / (dx * dx + dy * dy);
    if (t <= 0) return startLatLng;
    if (t >= 1) return endLatLng;
    return LatLng(sy + t * dy, sx + t * dx);
  }
}
