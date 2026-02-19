import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/attraction_model.dart';
import '../../data/attractions_data.dart';
import 'attraction_details_screen.dart';

class MapHomePage extends StatefulWidget {
  const MapHomePage({super.key});
  @override
  State<MapHomePage> createState() => _MapHomePageState();
}

class _MapHomePageState extends State<MapHomePage> {
  final MapController _mapController = MapController();
  LatLng _currentLocation = const LatLng(37.9838, 23.7275);

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
  final serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) return;

  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.deniedForever ||
      permission == LocationPermission.denied) {
    return;
  }

  Position? position;

 
  try {
    position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
      timeLimit: const Duration(seconds: 10),
    );
  } catch (_) {}

 
  position ??= await Geolocator.getLastKnownPosition();

  if (position == null) return;

  if (!mounted) return;
  setState(() => _currentLocation = LatLng(position!.latitude, position.longitude));
  _mapController.move(_currentLocation, 14.0);
}


  void _openAttractionDetails(Attraction attraction) {
    final currentIndex = attractions.indexOf(attraction);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AttractionDetailsPage(
          allAttractions: attractions,
          currentIndex: currentIndex == -1 ? 0 : currentIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEBF4F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEBF4F6),
        elevation: 0,
        centerTitle: true,
        title: const Column(
          children: [
            Text(
              "Map",
              style: TextStyle(
                color: Color(0xFF0D2C54),
                fontWeight: FontWeight.bold,
                fontSize: 24,
                fontFamily: 'serif',
              ),
            ),
            Text(
              "Athens",
              style: TextStyle(color: Color(0xFF3E4C63), fontSize: 16),
            )
          ],
        ),
      
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(initialCenter: _currentLocation, initialZoom: 13.0),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            tileBuilder: (context, widget, tile) => ColorFiltered(
              colorFilter: const ColorFilter.matrix(<double>[
                0.95, 0, 0, 0, 0,
                0, 0.9, 0, 0, 0,
                0, 0, 0.85, 0, 0,
                0, 0, 0, 1, 0
              ]),
              child: widget,
            ),
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: _currentLocation,
                width: 60,
                height: 60,
                child: const Column(
                  children: [Icon(Icons.person_pin_circle, size: 40, color: Colors.blueAccent)],
                ),
              ),
              ...attractions
                  .map(
                    (attraction) => Marker(
                      point: attraction.location,
                      width: 50,
                      height: 50,
                      child: GestureDetector(
                        onTap: () => _openAttractionDetails(attraction),
                        child: const Icon(Icons.star, size: 45, color: Colors.black87),
                      ),
                    ),
                  )
                  .toList(),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _determinePosition,
        backgroundColor: const Color(0xFF3E4C63),
        child: const Icon(Icons.my_location, color: Colors.white),
      ),
    );
  }
}
