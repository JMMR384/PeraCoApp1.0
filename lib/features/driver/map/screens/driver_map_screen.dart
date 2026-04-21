import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:peraco/core/constants/colors.dart';
import 'package:peraco/core/constants/text_styles.dart';
import 'package:peraco/features/driver/map/models/map_point.dart';
import 'package:peraco/features/driver/map/widgets/legend_dot.dart';
import 'package:peraco/features/driver/map/widgets/map_button.dart';
import 'package:url_launcher/url_launcher.dart';

class DriverMapScreen extends ConsumerStatefulWidget {
  const DriverMapScreen({super.key});
  @override
  ConsumerState<DriverMapScreen> createState() => _DriverMapScreenState();
}

class _DriverMapScreenState extends ConsumerState<DriverMapScreen> {
  final MapController _mapController = MapController();

  LatLng _myLocation = const LatLng(4.6097, -74.0817);
  bool _locationLoaded = false;

  final List<MapPoint> _pickupPoints = const [
    MapPoint(name: 'Finca El Paraiso', address: 'Corabastos, Kennedy', lat: 4.6280, lng: -74.1530, type: PointType.pickup),
    MapPoint(name: 'Plaza de Mercado', address: 'Plaza Samper Mendoza', lat: 4.6220, lng: -74.0810, type: PointType.pickup),
  ];

  final List<MapPoint> _deliveryPoints = const [
    MapPoint(name: 'Cliente Jimmy', address: 'Calle 45 #12-34, Chapinero', lat: 4.6486, lng: -74.0628, type: PointType.delivery),
    MapPoint(name: 'Cliente Maria', address: 'Carrera 7 #89-12, Usaquen', lat: 4.6950, lng: -74.0320, type: PointType.delivery),
  ];

  MapPoint? _selectedPoint;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
      setState(() {
        _myLocation = LatLng(position.latitude, position.longitude);
        _locationLoaded = true;
      });
      _mapController.move(_myLocation, 14);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _myLocation,
            initialZoom: 12.0,
            onTap: (_, __) => setState(() => _selectedPoint = null),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.peracoo.peraco',
            ),

            PolylineLayer(polylines: [
              if (_pickupPoints.isNotEmpty && _deliveryPoints.isNotEmpty)
                Polyline(
                  points: [
                    LatLng(_pickupPoints[0].lat, _pickupPoints[0].lng),
                    _myLocation,
                    LatLng(_deliveryPoints[0].lat, _deliveryPoints[0].lng),
                  ],
                  color: PeraCoColors.primary.withValues(alpha: 0.5),
                  strokeWidth: 3,
                  pattern: const StrokePattern.dotted(),
                ),
            ]),

            MarkerLayer(markers: [
              Marker(
                point: _myLocation,
                width: 50, height: 50,
                child: GestureDetector(
                  onTap: () => setState(() => _selectedPoint = MapPoint(
                      name: 'Mi ubicacion',
                      address: _locationLoaded ? 'Ubicacion actual' : 'Bogota (predeterminado)',
                      lat: _myLocation.latitude, lng: _myLocation.longitude, type: PointType.me)),
                  child: Container(
                      decoration: BoxDecoration(
                          color: PeraCoColors.primary, shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [BoxShadow(color: PeraCoColors.primary.withValues(alpha: 0.3), blurRadius: 8, spreadRadius: 2)]),
                      child: const Icon(Icons.delivery_dining, color: Colors.white, size: 24)),
                ),
              ),

              ..._pickupPoints.map((point) => Marker(
                point: LatLng(point.lat, point.lng),
                width: 44, height: 44,
                child: GestureDetector(
                  onTap: () => setState(() => _selectedPoint = point),
                  child: Container(
                      decoration: BoxDecoration(
                          color: PeraCoColors.warning, shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2)),
                      child: const Icon(Icons.store, color: Colors.white, size: 20)),
                ),
              )),

              ..._deliveryPoints.map((point) => Marker(
                point: LatLng(point.lat, point.lng),
                width: 44, height: 44,
                child: GestureDetector(
                  onTap: () => setState(() => _selectedPoint = point),
                  child: Container(
                      decoration: BoxDecoration(
                          color: PeraCoColors.primary, shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2)),
                      child: const Icon(Icons.person, color: Colors.white, size: 20)),
                ),
              )),
            ]),
          ],
        ),

        // Header
        Positioned(top: 0, left: 0, right: 0,
            child: SafeArea(child: Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)]),
              child: Row(children: [
                const Icon(Icons.map_outlined, color: PeraCoColors.primary),
                const SizedBox(width: 10),
                Text('Mapa de Entregas', style: PeraCoText.bodyBold(context)),
                const Spacer(),
                if (_locationLoaded)
                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: PeraCoColors.greenPastel, borderRadius: BorderRadius.circular(6)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Container(width: 6, height: 6, decoration: const BoxDecoration(color: PeraCoColors.primary, shape: BoxShape.circle)),
                        const SizedBox(width: 4),
                        Text('GPS', style: PeraCoText.caption(context).copyWith(color: PeraCoColors.primary, fontSize: 10)),
                      ]))
                else
                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: PeraCoColors.warning.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                      child: Text('Sin GPS', style: PeraCoText.caption(context).copyWith(color: PeraCoColors.warning, fontSize: 10))),
                const SizedBox(width: 8),
                const LegendDot(color: PeraCoColors.warning, label: 'Recoger'),
                const SizedBox(width: 8),
                const LegendDot(color: PeraCoColors.primary, label: 'Entregar'),
              ]),
            ))),

        // Info card
        if (_selectedPoint != null)
          Positioned(bottom: 100, left: 16, right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 12)]),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Row(children: [
                    Container(width: 44, height: 44,
                        decoration: BoxDecoration(
                            color: _selectedPoint!.type == PointType.pickup
                                ? PeraCoColors.warning.withValues(alpha: 0.15)
                                : _selectedPoint!.type == PointType.delivery
                                ? PeraCoColors.primary.withValues(alpha: 0.15)
                                : PeraCoColors.primaryLight.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12)),
                        child: Icon(
                            _selectedPoint!.type == PointType.pickup ? Icons.store
                                : _selectedPoint!.type == PointType.delivery ? Icons.person
                                : Icons.delivery_dining,
                            color: _selectedPoint!.type == PointType.pickup ? PeraCoColors.warning
                                : _selectedPoint!.type == PointType.delivery ? PeraCoColors.primary
                                : PeraCoColors.primaryLight,
                            size: 22)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_selectedPoint!.name, style: PeraCoText.bodyBold(context)),
                      Text(_selectedPoint!.address, style: PeraCoText.caption(context).copyWith(color: PeraCoColors.textSecondary)),
                    ])),
                    IconButton(onPressed: () => setState(() => _selectedPoint = null),
                        icon: const Icon(Icons.close, size: 20, color: PeraCoColors.textHint)),
                  ]),
                  if (_selectedPoint!.type != PointType.me) ...[
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: OutlinedButton.icon(
                          onPressed: () => _openInMaps(_selectedPoint!),
                          icon: const Icon(Icons.directions, size: 18),
                          label: const Text('Google Maps'),
                          style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              side: const BorderSide(color: PeraCoColors.primary)))),
                      const SizedBox(width: 10),
                      Expanded(child: OutlinedButton.icon(
                          onPressed: () => _openInWaze(_selectedPoint!),
                          icon: const Icon(Icons.navigation, size: 18),
                          label: const Text('Waze'),
                          style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              side: const BorderSide(color: PeraCoColors.primaryLight)))),
                    ]),
                  ],
                ]),
              )),

        // Botones zoom y ubicacion
        Positioned(right: 16, bottom: 180,
            child: Column(children: [
              MapButton(icon: Icons.add, onTap: () {
                final zoom = _mapController.camera.zoom + 1;
                _mapController.move(_mapController.camera.center, zoom);
              }),
              const SizedBox(height: 8),
              MapButton(icon: Icons.remove, onTap: () {
                final zoom = _mapController.camera.zoom - 1;
                _mapController.move(_mapController.camera.center, zoom);
              }),
              const SizedBox(height: 8),
              MapButton(icon: Icons.my_location, onTap: () {
                if (_locationLoaded) {
                  _mapController.move(_myLocation, 15);
                } else {
                  _getCurrentLocation();
                }
              }),
            ])),
      ]),
    );
  }

  void _openInMaps(MapPoint point) async {
    final url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${point.lat},${point.lng}&travelmode=driving');
    if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  void _openInWaze(MapPoint point) async {
    final url = Uri.parse('https://waze.com/ul?ll=${point.lat},${point.lng}&navigate=yes');
    if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
  }
}
