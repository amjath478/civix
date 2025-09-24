import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as gc;
import '../models/issue_model.dart';

class LocationService {
  // Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Check location permission
  Future<LocationPermission> checkLocationPermission() async {
    return await Geolocator.checkPermission();
  }

  // Request location permission
  Future<LocationPermission> requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    
    return permission;
  }

  // Get current location
  Future<LocationData?> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled. Please enable location services.';
      }

      // Check and request permission
      LocationPermission permission = await checkLocationPermission();
      if (permission == LocationPermission.denied) {
        permission = await requestLocationPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions are denied. Please grant location permission.';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied. Please enable them in settings.';
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // Try reverse geocoding to get a human readable place (city/town/locality)
      String address = '';
      try {
        final placemarks = await gc.placemarkFromCoordinates(position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          // Prefer locality (city/town). Fallback to subAdministrativeArea, administrativeArea or country.
          address = (p.locality ?? '').trim();
          if (address.isEmpty) address = (p.subAdministrativeArea ?? '').trim();
          if (address.isEmpty) address = (p.administrativeArea ?? '').trim();
          if (address.isEmpty) address = (p.country ?? '').trim();
        }
      } catch (e) {
        // Ignore reverse geocoding failures and fallback to lat/lng string below
      }

      if (address.isEmpty) {
        address = 'Lat: ${position.latitude.toStringAsFixed(6)}, Lng: ${position.longitude.toStringAsFixed(6)}';
      }

      return LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        address: address,
      );
    } catch (e) {
      throw 'Failed to get current location: ${e.toString()}';
    }
  }

  // Calculate distance between two locations
  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }
}