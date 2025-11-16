import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../core/models/models.dart';
import '../../core/repositories/horus_repository.dart';

class RecordTripScreen extends StatefulWidget {
  const RecordTripScreen({super.key, required this.macrorutaId});

  final int macrorutaId;

  @override
  State<RecordTripScreen> createState() => _RecordTripScreenState();
}

class _RecordTripScreenState extends State<RecordTripScreen> {
  static const LatLng _defaultCenter = LatLng(-17.7833, -63.1821);

  final MapController _mapController = MapController();
  double _mapZoom = 15;
  HorusRepository? _repository;
  Future<void>? _initialLoad;
  List<MicrorutaDto> _microrutas = const [];
  List<RecolectorStatusDto> _collectors = const [];
  int? _selectedMicroruta;
  int? _selectedCollector;
  Trip? _activeTrip;
  List<LatLng> _trackPoints = const [];
  StreamSubscription<Position>? _positionSub;
  bool _isStarting = false;
  bool _isFinishing = false;
  String? _loadError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _repository ??= HorusRepositoryScope.of(context);
    _initialLoad ??= _loadInitialData();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      final repo = _repository;
      if (repo == null) return;
      final results = await Future.wait([
        repo.getMicrorutas(macrorutaId: widget.macrorutaId),
        repo.getCollectorStatus(macrorutaId: widget.macrorutaId),
      ]);
      final microrutas = results[0] as List<MicrorutaDto>;
      final collectors = results[1] as List<RecolectorStatusDto>;
      if (!mounted) return;
      setState(() {
        _microrutas = microrutas;
        _collectors = collectors;
        _selectedMicroruta =
            microrutas.isNotEmpty ? microrutas.first.id : null;
        _selectedCollector =
            collectors.isNotEmpty ? collectors.first.recolectorId : null;
        _loadError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loadError = error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final canStartTrip =
        _microrutas.isNotEmpty &&
        _collectors.isNotEmpty &&
        _activeTrip == null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar recorrido'),
      ),
      body: FutureBuilder<void>(
        future: _initialLoad,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_loadError != null) {
            return _ErrorState(message: _loadError!, onRetry: _reload);
          }
          if (_microrutas.isEmpty || _collectors.isEmpty) {
            return _EmptyState(onRetry: _reload);
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  runSpacing: 12,
                  spacing: 12,
                  children: [
                    SizedBox(
                      width: 240,
                      child: DropdownButtonFormField<int>(
                        value: _selectedMicroruta,
                        decoration: const InputDecoration(
                          labelText: 'Microruta',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          for (final route in _microrutas)
                            DropdownMenuItem(
                              value: route.id,
                              child: Text(route.nombre),
                            ),
                        ],
                        onChanged: _activeTrip == null
                            ? (value) => setState(() => _selectedMicroruta = value)
                            : null,
                      ),
                    ),
                    SizedBox(
                      width: 240,
                      child: DropdownButtonFormField<int>(
                        value: _selectedCollector,
                        decoration: const InputDecoration(
                          labelText: 'Recolector',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          for (final collector in _collectors)
                            DropdownMenuItem(
                              value: collector.recolectorId,
                              child: Text(collector.recolectorNombre),
                            ),
                        ],
                        onChanged: _activeTrip == null
                            ? (value) => setState(() => _selectedCollector = value)
                            : null,
                      ),
                    ),
                    FilledButton.icon(
                      icon: _isStarting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.play_arrow),
                      label: const Text('Iniciar recorrido'),
                      onPressed: _activeTrip == null && !_isStarting
                          ? _startTrip
                          : null,
                    ),
                    OutlinedButton.icon(
                      icon: _isFinishing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.stop),
                      label: const Text('Finalizar recorrido'),
                      onPressed: _activeTrip != null && !_isFinishing
                          ? _finishTrip
                          : null,
                    ),
                    if (_activeTrip != null)
                      Chip(
                        avatar: const Icon(Icons.timer, size: 18),
                        label: Text(_tripDurationLabel()),
                      ),
                    if (_trackPoints.length > 1)
                      Chip(
                        avatar: const Icon(Icons.social_distance, size: 18),
                        label: Text('${_distanceKm().toStringAsFixed(2)} km'),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _trackPoints.isNotEmpty
                        ? _trackPoints.last
                        : _defaultCenter,
                    initialZoom: _mapZoom,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                    onPositionChanged: (position, _) {
                      _mapZoom = position.zoom;
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.horusfront.app',
                      retinaMode: true,
                    ),
                    if (_trackPoints.length > 1)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _trackPoints,
                            strokeWidth: 5,
                            color: Colors.green,
                          ),
                        ],
                      ),
                    if (_trackPoints.isNotEmpty)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _trackPoints.last,
                            alignment: Alignment.center,
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.radio_button_checked,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
        floatingActionButton: canStartTrip
          ? FloatingActionButton.extended(
              onPressed: _startTrip,
              icon: const Icon(Icons.play_circle),
              label: const Text('Iniciar'),
            )
          : null,
    );
  }

  Future<void> _reload() async {
    setState(() {
      _initialLoad = null;
      _loadError = null;
    });
    _initialLoad = _loadInitialData();
  }

  Future<void> _startTrip() async {
    final repo = _repository;
    if (repo == null) return;
    if (_selectedMicroruta == null || _selectedCollector == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona recolector y microruta.')),
      );
      return;
    }
    final granted = await _ensurePermission();
    if (!granted) return;
    setState(() => _isStarting = true);
    try {
      final startPosition = await Geolocator.getCurrentPosition();
      final trip = await repo.startTrip(
        StartTripDto(
          recolectorId: _selectedCollector!,
          microrutaId: _selectedMicroruta!,
          inicio: DateTime.now(),
        ),
      );
      final firstPoint = LatLng(
        startPosition.latitude,
        startPosition.longitude,
      );
      await repo.sendPosition(
        PositionUpdateDto(
          tripId: trip.id,
          latitude: firstPoint.latitude,
          longitude: firstPoint.longitude,
          timestamp: DateTime.now(),
          speed: startPosition.speed == 0 ? null : startPosition.speed,
        ),
      );
      _trackPoints = [firstPoint];
      _activeTrip = trip;
      if (!mounted) return;
      setState(() {
        _activeTrip = trip;
        _trackPoints = [firstPoint];
      });
      _mapZoom = 17;
      _mapController.move(firstPoint, _mapZoom);
      _listenToPositions();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recorrido iniciado.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo iniciar el recorrido: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isStarting = false);
      }
    }
  }

  Future<void> _finishTrip() async {
    final repo = _repository;
    final trip = _activeTrip;
    if (repo == null || trip == null) return;
    setState(() => _isFinishing = true);
    _positionSub?.cancel();
    try {
      await repo.finishTrip(
        FinishTripDto(
          tripId: trip.id,
          fin: DateTime.now(),
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recorrido finalizado.')),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo finalizar: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _activeTrip = null;
          _isFinishing = false;
        });
      }
    }
  }

  void _listenToPositions() {
    _positionSub?.cancel();
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 5,
      ),
    ).listen(
      (position) {
        final trip = _activeTrip;
        if (trip == null) return;
        final repo = _repository;
        final point = LatLng(position.latitude, position.longitude);
        setState(() {
          _trackPoints = [..._trackPoints, point];
        });
        _mapController.move(point, _mapZoom);
        repo?.sendPosition(
          PositionUpdateDto(
            tripId: trip.id,
            latitude: point.latitude,
            longitude: point.longitude,
            timestamp: DateTime.now(),
            speed: position.speed == 0 ? null : position.speed,
          ),
        );
      },
      onError: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error obteniendo ubicación: $error')),
        );
      },
    );
  }

  Future<bool> _ensurePermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Activa el GPS para registrar el recorrido.'),
          ),
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
          const SnackBar(
            content: Text('Permiso de ubicación denegado.'),
          ),
        );
      }
      return false;
    }
    return true;
  }

  double _distanceKm() {
    if (_trackPoints.length < 2) return 0;
    const distance = Distance();
    double sum = 0;
    for (var i = 1; i < _trackPoints.length; i++) {
      sum += distance.as(
        LengthUnit.Kilometer,
        _trackPoints[i - 1],
        _trackPoints[i],
      );
    }
    return sum;
  }

  String _tripDurationLabel() {
    final trip = _activeTrip;
    if (trip == null) return '';
    final duration = DateTime.now().difference(trip.inicio);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    final parts = <String>[];
    if (hours > 0) parts.add('${hours}h');
    if (minutes > 0 || hours > 0) parts.add('${minutes}m');
    parts.add('${seconds}s');
    return parts.join(' ');
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('No hay recolectores o microrutas disponibles.'),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Actualizar')),
        ],
      ),
    );
  }
}
