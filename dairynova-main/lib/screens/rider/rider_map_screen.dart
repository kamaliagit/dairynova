import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:location/location.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Note: latlong2 ka import humne hata diya hai taakay error khatam ho jaye

class RiderMapScreen extends StatefulWidget {
  final String orderId;
  final double customerLat;
  final double customerLng;

  const RiderMapScreen({
    super.key,
    required this.orderId,
    required this.customerLat,
    required this.customerLng,
  });

  @override
  State<RiderMapScreen> createState() => _RiderMapScreenState();
}

class _RiderMapScreenState extends State<RiderMapScreen> {
  // Humne LatLng ki jagah simple variables use kiye hain
  double? _riderLat;
  double? _riderLng;

  final MapController _mapController = MapController();
  Location location = Location();

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  void _checkLocationPermission() async {
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) return;
    }

    PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }
    _listenToLocation();
  }

  void _listenToLocation() {
    location.onLocationChanged.listen((LocationData loc) {
      if (loc.latitude != null && loc.longitude != null) {
        if (mounted) {
          setState(() {
            _riderLat = loc.latitude;
            _riderLng = loc.longitude;
          });

          FirebaseFirestore.instance
              .collection('orders')
              .doc(widget.orderId)
              .update({
                'riderLatitude': loc.latitude,
                'riderLongitude': loc.longitude,
              });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Live Rider Tracking")),
      body: _riderLat == null
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: MapLatLng(_riderLat!, _riderLng!),
                initialZoom: 15.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.dairy_nova_app',
                ),
                MarkerLayer(
                  markers: [
                    // Customer Location
                    Marker(
                      point: MapLatLng(widget.customerLat, widget.customerLng),
                      width: 50,
                      height: 50,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                    // Rider Location
                    Marker(
                      point: MapLatLng(_riderLat!, _riderLng!),
                      width: 50,
                      height: 50,
                      child: const Icon(
                        Icons.directions_bike,
                        color: Colors.blue,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

dynamic MapLatLng(double lat, double lng) {
  return LatLng(lat, lng);
}

class LatLng {
  final double latitude;
  final double longitude;
  const LatLng(this.latitude, this.longitude);
}
