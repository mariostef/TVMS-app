import 'package:latlong2/latlong.dart';

class Attraction {
  final String name;
  final String description;
  final String imagePath;
  final LatLng location;

  Attraction({
    required this.name,
    required this.description,
    required this.imagePath,
    required this.location,
  });
}