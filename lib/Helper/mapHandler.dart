import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class MapHandler extends StatefulWidget {
  const MapHandler({super.key});

  @override
  State<MapHandler> createState() => _MapHandlerState();
}

class _MapHandlerState extends State<MapHandler> {
  final Location _location = Location();

  GoogleMapController? _mapController;
  LatLng? _initialPosition;
  bool _isLoading = true;
  bool _isFollowingUser = true;

  StreamSubscription<LocationData>? _locationSubscription;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    try {
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          setState(() => _isLoading = false);
          return;
        }
      }

      PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          setState(() => _isLoading = false);
          return;
        }
      }

      final currentLocation = await _location.getLocation();
      final lat = currentLocation.latitude;
      final lng = currentLocation.longitude;

      if (lat == null || lng == null) {
        setState(() => _isLoading = false);
        return;
      }

      _initialPosition = LatLng(lat, lng);
      setState(() => _isLoading = false);


      _locationSubscription = _location.onLocationChanged.listen((LocationData newLoc) {
        if (!mounted) return;

        final newLat = newLoc.latitude;
        final newLng = newLoc.longitude;
        if (newLat == null || newLng == null) return;

        if (_isFollowingUser && _mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLng(LatLng(newLat, newLng)),
          );
        }
      });

    } catch (e) {
      debugPrint('Error fetching location: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_initialPosition == null) {
      return const Center(child: Text("Unable to load map"));
    }

    return GoogleMap(
      onMapCreated: (controller) => _mapController = controller,
      initialCameraPosition: CameraPosition(
        target: _initialPosition!,
        zoom: 14,
      ),
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
    );
  }
}

