import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class NearbyMosquesMap extends StatefulWidget {
  const NearbyMosquesMap({Key? key}) : super(key: key);

  @override
  State<NearbyMosquesMap> createState() => _NearbyMosquesMapState();
}

class _NearbyMosquesMapState extends State<NearbyMosquesMap> {
  GoogleMapController? _mapController;
  LatLng? _currentLocation;
  Set<Marker> _markers = {};

  final String apiKey = 'YOUR_API_KEY_HERE'; // Replace with your API key

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnackBar("Location services are disabled.");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnackBar("Location permission denied.");
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showSnackBar("Location permissions are permanently denied.");
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final current = LatLng(position.latitude, position.longitude);

      setState(() {
        _currentLocation = current;
        _markers.add(
          Marker(
            markerId: const MarkerId('current_location'),
            position: current,
            infoWindow: const InfoWindow(title: 'You Are Here'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          ),
        );
      });

      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(current, 14));
      _getNearbyMosques(current.latitude, current.longitude);
    } catch (e) {
      _showSnackBar("Error getting location: $e");
    }
  }

  Future<void> _getNearbyMosques(double lat, double lng) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
          '?location=$lat,$lng'
          '&radius=3000'
          '&keyword=mosque'
          '&type=mosque'
          '&key=$apiKey',
    );

    try {
      final response = await http.get(url);
      final data = json.decode(response.body);

      if (data['status'] == 'OK') {
        Set<Marker> newMarkers = Set.from(_markers); // Keep current location

        for (var place in data['results']) {
          final lat = place['geometry']['location']['lat'];
          final lng = place['geometry']['location']['lng'];
          final name = place['name'];

          newMarkers.add(
            Marker(
              markerId: MarkerId(place['place_id']),
              position: LatLng(lat, lng),
              infoWindow: InfoWindow(title: name),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            ),
          );
        }

        if (mounted) {
          setState(() {
            _markers = newMarkers;
          });
        }
      } else if (data['status'] == 'ZERO_RESULTS') {
        _showSnackBar("No nearby mosques found.");
      } else {
        _showSnackBar("Places API error: ${data['status']}");
      }
    } catch (e) {
      _showSnackBar("Error fetching nearby mosques: $e");
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nearby Mosques')),
      body: _currentLocation == null
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
        onMapCreated: (controller) => _mapController = controller,
        initialCameraPosition: CameraPosition(
          target: _currentLocation!,
          zoom: 14,
        ),
        markers: _markers,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
      ),
    );
  }
}
