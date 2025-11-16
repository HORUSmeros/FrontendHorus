import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../app/theme/app_colors.dart';
import '../../core/models/models.dart';
import '../../core/repositories/horus_repository.dart';
import '../../core/utils/route_recalculator.dart';

class RoutesScreen extends StatefulWidget {
  const RoutesScreen({super.key});

  @override
  State<RoutesScreen> createState() => _RoutesScreenState();
}

class _RoutesScreenState extends State<RoutesScreen> {
  HorusRepository? _repository;
  Future<_RoutesData>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repo = HorusRepositoryScope.of(context);
    if (_repository != repo || _future == null) {
      _repository = repo;
      _future = _load(repo);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_RoutesData>(
      future: _future,
      builder: (context, snapshot) {
        final isLoading =
            snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData;
        final data = snapshot.data;

        return Scaffold(
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : data == null
              ? const Center(child: Text('No se pudo cargar la información.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Macroruta Verde – En progreso',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          _SummaryChip(
                            icon: Icons.percent,
                            label: 'Cobertura',
                            value: '${data.coverage.toStringAsFixed(0)}%',
                          ),
                          const SizedBox(width: 12),
                          _SummaryChip(
                            icon: Icons.place_outlined,
                            label: 'Distancia',
                            value: data.distanceLabel,
                          ),
                          const SizedBox(width: 12),
                          _SummaryChip(
                            icon: Icons.warning_amber_outlined,
                            label: 'Incidentes',
                            value: '${data.incidentesActivos} activos',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              AspectRatio(
                                aspectRatio: 16 / 7,
                                child: _RouteMap(
                                  statuses: data.statuses,
                                  microrutas: data.microrutas,
                                  repository: _repository!,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Recolectores Activos',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _ActiveCollectorsList(
                                statuses: data.statuses,
                                collectors: data.collectors,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          floatingActionButton: null,
        );
      },
    );
  }

  Future<_RoutesData> _load(HorusRepository repository) async {
    final now = DateTime.now();
    final statuses = await repository.getCollectorStatus();
    final collectors = await repository.getCollectors();
    final microrutas = await repository.getMicrorutas();
    final trips = await repository.getTrips(date: now);
    final coverageSum = trips.fold<double>(
      0,
      (prev, trip) => prev + trip.coberturaPorciento,
    );
    final coverage = trips.isEmpty ? 0.0 : coverageSum / trips.length;
    final distanceKm =
        trips.map((t) => t.distanciaMetros).fold<double>(0, (p, v) => p + v) /
        1000;
    final incidentes = trips.fold<int>(
      0,
      (prev, trip) => prev + trip.incidentes,
    );
    final macrorutaId = microrutas.isNotEmpty
        ? microrutas.first.macrorutaId
        : 1;

    return _RoutesData(
      statuses: statuses,
      collectors: collectors,
      microrutas: microrutas,
      coverage: coverage,
      distanceLabel: '${distanceKm.toStringAsFixed(1)} km / 12 km',
      incidentesActivos: incidentes,
      macrorutaId: macrorutaId,
    );
  }
}

class _RoutesData {
  const _RoutesData({
    required this.statuses,
    required this.collectors,
    required this.microrutas,
    required this.coverage,
    required this.distanceLabel,
    required this.incidentesActivos,
    required this.macrorutaId,
  });

  final List<RecolectorStatusDto> statuses;
  final List<CollectorSummary> collectors;
  final List<MicrorutaDto> microrutas;
  final double coverage;
  final String distanceLabel;
  final int incidentesActivos;
  final int macrorutaId;
}

class _RouteMap extends StatefulWidget {
  const _RouteMap({
    required this.statuses,
    required this.microrutas,
    required this.repository,
  });

  final List<RecolectorStatusDto> statuses;
  final List<MicrorutaDto> microrutas;
  final HorusRepository repository;

  static const LatLng _defaultCenter = LatLng(-17.7833, -63.1821);

  @override
  State<_RouteMap> createState() => _RouteMapState();
}

class _RouteMapState extends State<_RouteMap> {
  final Map<int, List<LatLng>> _geometryOverrides = {};
  List<LatLng> _draftPoints = const <LatLng>[];
  List<LatLng> _recalculatedPath = const <LatLng>[];
  int? _selectedMicrorutaId;
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isRecalculating = false;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _selectedMicrorutaId = widget.microrutas.isNotEmpty
        ? widget.microrutas.first.id
        : null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _mapReady = true);
    });
  }

  @override
  void didUpdateWidget(covariant _RouteMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedMicrorutaId == null && widget.microrutas.isNotEmpty) {
      _selectedMicrorutaId = widget.microrutas.first.id;
    }
    if (_selectedMicrorutaId != null &&
        widget.microrutas.every((route) => route.id != _selectedMicrorutaId)) {
      _selectedMicrorutaId = widget.microrutas.isNotEmpty
          ? widget.microrutas.first.id
          : null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_mapReady) {
      return const SizedBox(
        height: 420,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final collectorPositions = widget.statuses
        .where((status) => status.latitude != null && status.longitude != null)
        .map((status) => (status, LatLng(status.latitude!, status.longitude!)))
        .toList(growable: false);

    final microrutaPolylines = widget.microrutas
        .map((route) => (route, _geometryFor(route)))
        .where((entry) => entry.$2.length > 1)
        .toList(growable: false);

    final geoPoints = [
      ...microrutaPolylines.expand((entry) => entry.$2),
      ...collectorPositions.map((entry) => entry.$2),
      if (_recalculatedPath.isNotEmpty) ..._recalculatedPath,
      if (_draftPoints.isNotEmpty) ..._draftPoints,
    ];

    final bounds = _buildBounds(geoPoints);
    final hasGeoData = geoPoints.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: _RouteMap._defaultCenter,
                initialZoom: 13,
                initialCameraFit: bounds != null
                    ? CameraFit.bounds(
                        bounds: bounds,
                        padding: const EdgeInsets.all(24),
                      )
                    : null,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
                onTap: _mapReady ? _handleMapTap : null,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.horusfront.app',
                  retinaMode: true,
                ),
                if (_isEditing && _draftPoints.length > 1)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _draftPoints,
                        color: AppColors.info,
                        strokeWidth: 5,
                      ),
                    ],
                  ),
                if (collectorPositions.isNotEmpty)
                  MarkerLayer(
                    rotate: false,
                    markers: [
                      for (final (status, point) in collectorPositions)
                        Marker(
                          width: 140,
                          height: 80,
                          point: point,
                          alignment: Alignment.topCenter,
                          child: _RouteMarker(status: status),
                        ),
                    ],
                  ),
                if (_recalculatedPath.length > 1)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _recalculatedPath,
                        color: AppColors.info,
                        strokeWidth: 4,
                        borderStrokeWidth: 1,
                        borderColor: Colors.white,
                      ),
                    ],
                  ),
                if (!_isEditing && microrutaPolylines.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      for (final (route, points) in microrutaPolylines)
                        Polyline(
                          points: points,
                          color: route.id == _selectedMicrorutaId
                              ? AppColors.primary
                              : AppColors.primary.withValues(alpha: .3),
                          strokeWidth: route.id == _selectedMicrorutaId ? 5 : 3,
                        ),
                    ],
                  ),
              ],
            ),
            if (!hasGeoData)
              Positioned.fill(
                child: Container(
                  color: Colors.white.withValues(alpha: .8),
                  alignment: Alignment.center,
                  child: const Text(
                    'Sin geometría disponible para las microrutas.',
                  ),
                ),
              ),
            Positioned(
              top: 16,
              left: 16,
              child: _MicrorutaSelector(
                microrutas: widget.microrutas,
                selectedId: _selectedMicrorutaId,
                onChanged: _isSaving || _isEditing
                    ? null
                    : (value) => setState(() => _selectedMicrorutaId = value),
              ),
            ),
            if (_selectedMicrorutaId != null)
              Positioned(
                top: 16,
                right: 16,
                child: Wrap(
                  spacing: 8,
                  children: [
                    FilledButton.icon(
                      icon: _isRecalculating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.route),
                      label: const Text('Recalcular ruta'),
                      onPressed:
                          _isRecalculating || _isEditing ? null : _recalculateRoute,
                    ),
                    if (!_isEditing)
                      FilledButton.icon(
                        icon: const Icon(Icons.edit),
                        label: const Text('Editar ruta'),
                        onPressed: _isSaving ? null : _beginEditing,
                      )
                    else ...[
                      OutlinedButton.icon(
                        icon: const Icon(Icons.close),
                        label: const Text('Cancelar'),
                        onPressed: _isSaving ? null : _cancelEditing,
                      ),
                      FilledButton.icon(
                        icon: _isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: const Text('Guardar ruta'),
                        onPressed: _canSaveDraft ? _saveRoute : null,
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool get _canSaveDraft => _isEditing && !_isSaving && _draftPoints.length > 1;

  List<LatLng> _geometryFor(MicrorutaDto route) {
    final override = _geometryOverrides[route.id];
    if (override != null) return override;
    return route.points
        .map((point) => LatLng(point.latitude, point.longitude))
        .toList(growable: false);
  }

  LatLngBounds? _buildBounds(List<LatLng> points) {
    if (points.isEmpty) return null;
    if (points.length == 1) {
      return LatLngBounds.fromPoints([points.first, points.first]);
    }
    return LatLngBounds.fromPoints(points);
  }

  void _handleMapTap(TapPosition tapPosition, LatLng point) {
    if (!_isEditing) return;
    setState(() {
      _draftPoints = [..._draftPoints, point];
    });
  }

  void _beginEditing() {
    final routePoints = _currentRouteGeometry();
    setState(() {
      _isEditing = true;
      _draftPoints = routePoints ?? const <LatLng>[];
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _draftPoints = const <LatLng>[];
    });
  }

  List<LatLng>? _currentRouteGeometry() {
    final routeId = _selectedMicrorutaId;
    if (routeId == null || widget.microrutas.isEmpty) return null;
    final route = widget.microrutas.firstWhere(
      (item) => item.id == routeId,
      orElse: () => widget.microrutas.first,
    );
    final geometry =
        _geometryOverrides[routeId] ??
        route.points
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList(growable: false);
    return geometry;
  }

  Future<void> _saveRoute() async {
    final routeId = _selectedMicrorutaId;
    if (routeId == null || _draftPoints.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agrega al menos dos puntos para guardar la ruta.'),
        ),
      );
      return;
    }
    setState(() {
      _isSaving = true;
    });
    final payload = _draftPoints
        .map(
          (point) => MicrorutaPointDto(
            latitude: point.latitude,
            longitude: point.longitude,
          ),
        )
        .toList(growable: false);
    try {
      await widget.repository.updateMicrorutaGeometry(
        microrutaId: routeId,
        points: payload,
      );
      if (!mounted) return;
      setState(() {
        _geometryOverrides[routeId] = List<LatLng>.from(_draftPoints);
        _isEditing = false;
        _draftPoints = const <LatLng>[];
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ruta actualizada correctamente.')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar la ruta: $error')),
      );
    }
  }

  Future<void> _recalculateRoute() async {
    final routeId = _selectedMicrorutaId;
    if (routeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una microruta.')),
      );
      return;
    }
    final route = widget.microrutas.firstWhere(
      (item) => item.id == routeId,
      orElse: () => widget.microrutas.first,
    );
    if (route.points.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La microruta no tiene geometría.')),
      );
      return;
    }
    final granted = await _ensurePermission();
    if (!granted) return;
    setState(() {
      _isRecalculating = true;
    });
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final path = RouteRecalculator.recalculate(
        currentPosition: LatLng(position.latitude, position.longitude),
        originalPoints: route.points,
      );
      if (!mounted) return;
      setState(() {
        _recalculatedPath = path;
        _isRecalculating = false;
      });
      if (path.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se recibieron puntos de ruta.')),
        );
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isRecalculating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo recalcular la ruta: $error')),
      );
    }
  }

  Future<bool> _ensurePermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Activa el GPS para recalcular.')),
        );
      }
      return false;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permiso de ubicación denegado.')),
        );
      }
      return false;
    }
    return true;
  }
}

class _MicrorutaSelector extends StatelessWidget {
  const _MicrorutaSelector({
    required this.microrutas,
    required this.selectedId,
    required this.onChanged,
  });

  final List<MicrorutaDto> microrutas;
  final int? selectedId;
  final ValueChanged<int?>? onChanged;

  @override
  Widget build(BuildContext context) {
    if (microrutas.isEmpty) {
      return const SizedBox.shrink();
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: selectedId,
            icon: const Icon(Icons.keyboard_arrow_down),
            hint: const Text('Microruta'),
            items: [
              for (final route in microrutas)
                DropdownMenuItem<int>(
                  value: route.id,
                  child: Text(route.nombre),
                ),
            ],
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}

class _RouteMarker extends StatelessWidget {
  const _RouteMarker({required this.status});

  final RecolectorStatusDto status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status.estado) {
      'Fuera de ruta' => AppColors.danger,
      'Sin señal' => AppColors.warning,
      _ => AppColors.primary,
    };

    return Column(
      children: [
        Icon(Icons.location_pin, color: color, size: 28),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .08),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            status.recolectorNombre,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
      ],
    );
  }
}

class _ActiveCollectorsList extends StatelessWidget {
  const _ActiveCollectorsList({
    required this.statuses,
    required this.collectors,
  });

  final List<RecolectorStatusDto> statuses;
  final List<CollectorSummary> collectors;

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('hh:mm a');

    final items = <Widget>[];

    if (statuses.isNotEmpty) {
      items.addAll(
        statuses.map((status) => _ActiveCollectorTile(
              name: status.recolectorNombre,
              statusLabel: status.estado,
              microruta: status.microrutaNombre,
              timestamp: status.ultimaActualizacion,
            )),
      );
    } else {
      final activeCollectors = collectors.where((collector) {
        final estado = collector.estado.toLowerCase();
        return estado != 'inactivo';
      }).toList();

      items.addAll(
        activeCollectors.map((collector) => _ActiveCollectorTile(
              name: collector.nombre,
              statusLabel: collector.estado,
              microruta: collector.macroruta,
              timestamp: collector.ultimaActividad,
            )),
      );
    }

    if (items.isEmpty) {
      return const Text('No hay recolectores activos en este momento.');
    }

    return Column(children: items);
  }
}

class _ActiveCollectorTile extends StatelessWidget {
  const _ActiveCollectorTile({
    required this.name,
    required this.statusLabel,
    required this.microruta,
    required this.timestamp,
  });

  final String name;
  final String statusLabel;
  final String microruta;
  final DateTime? timestamp;

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('hh:mm a');
    final color = _colorFor(statusLabel);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: .15),
        child: Icon(Icons.person, color: color),
      ),
      title: Text(name),
      subtitle: Text(statusLabel, style: TextStyle(color: color)),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(microruta, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(timeFormat.format(timestamp ?? DateTime.now())),
        ],
      ),
    );
  }

  Color _colorFor(String estado) {
    switch (estado) {
      case 'Fuera de ruta':
      case 'Desviada':
        return AppColors.danger;
      case 'Sin señal':
        return AppColors.warning;
      default:
        return AppColors.primary;
    }
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primaryDark),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelSmall),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
