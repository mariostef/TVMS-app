import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/attraction_model.dart';
import '../camera/take_selfie_screen.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter/foundation.dart'; // για kIsWeb


class AttractionDetailsPage extends StatefulWidget {
  final List<Attraction> allAttractions;
  final int currentIndex;

  const AttractionDetailsPage({
    super.key,
    required this.allAttractions,
    required this.currentIndex,
  });

  @override
  State<AttractionDetailsPage> createState() => _AttractionDetailsPageState();
}

class _AttractionDetailsPageState extends State<AttractionDetailsPage> {
  final double checkInRadiusMeters = 4000000.0;
  bool _canTakePhoto = false;

  Attraction get _attraction => widget.allAttractions[widget.currentIndex];

  Future<bool> _alreadyVisited() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('current_user');
    if (username == null) return false;

    final visitId = "Athens_${_attraction.name}";
    try {
      final doc =
          await FirebaseFirestore.instance.collection('travellers').doc(username).get();
      final data = doc.data();
      final unlocks = (data?['unlocked_attractions'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const <String>[];
      return unlocks.contains(visitId);
    } catch (_) {
      return false;
    }
  }
  Future<void> _strongBuzz() async {
  
  if (kIsWeb) return;

  try {
    final hasVibrator = await Vibration.hasVibrator() ?? false;
    if (hasVibrator) {
      // πιο αισθητό pattern
      await Vibration.vibrate(pattern: [0, 120, 60, 120]);
      return;
    }
  } catch (_) {}
 
  await HapticFeedback.heavyImpact();
}


Future<void> _checkProximity() async {
  Position userPosition = await Geolocator.getCurrentPosition();

  double distance = Geolocator.distanceBetween(
    userPosition.latitude,
    userPosition.longitude,
    _attraction.location.latitude,
    _attraction.location.longitude,
  );

  if (distance <= checkInRadiusMeters) {
    setState(() => _canTakePhoto = true);

    final visited = await _alreadyVisited();
    if (!mounted) return;

    if (visited) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You have already visited this destination."),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

   
    await _strongBuzz();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Colors.green,
        content: Text("You are here! Camera unlocked! 📸"),
        duration: Duration(seconds: 1),
      ),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TakeSelfiePage(
          cityName: "Athens",
          attractionName: _attraction.name,
        ),
      ),
    );
  } else {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text("Too far! Get closer."),
        ),
      );
    }
  }
}


  void _openCustomCamera() async {
    if (!_canTakePhoto) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must check-in first!")),
      );
      return;
    }

    final visited = await _alreadyVisited();
    if (!mounted) return;

    if (visited) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You have already visited this destination."),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TakeSelfiePage(
          cityName: "Athens",
          attractionName: _attraction.name,
        ),
      ),
    );
  }

  void _goToIndex(int newIndex) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => AttractionDetailsPage(
          allAttractions: widget.allAttractions,
          currentIndex: newIndex,
        ),
      ),
    );
  }

  void _goNext() {
    final len = widget.allAttractions.length;
    if (len == 0) return;
    final nextIndex = (widget.currentIndex + 1) % len;
    _goToIndex(nextIndex);
  }

  void _goPrev() {
    final len = widget.allAttractions.length;
    if (len == 0) return;
    final prevIndex = (widget.currentIndex - 1 + len) % len;
    _goToIndex(prevIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const SizedBox(),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_balance_outlined, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _attraction.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'serif',
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          ],
        ),
        centerTitle: true,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            _attraction.imagePath,
            fit: BoxFit.cover,
            color: Colors.black.withOpacity(0.6),
            colorBlendMode: BlendMode.darken,
            errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey),
          ),
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: GestureDetector(
                      onTap: _openCustomCamera,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _canTakePhoto ? Colors.green : Colors.white.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt_outlined,
                          color: Colors.white,
                          size: 25,
                        ),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: SingleChildScrollView(
                    child: Text(
                      _attraction.description,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontFamily: 'serif',
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 1),
                            blurRadius: 2,
                            color: Colors.black,
                          )
                        ],
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                        ),
                        onPressed: _goPrev,
                        icon: const Icon(Icons.arrow_back, size: 18),
                        label: const Text("Back"),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3E4C63),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 25,
                            vertical: 12,
                          ),
                          elevation: 5,
                        ),
                        onPressed: _checkProximity,
                        child: const Text(
                          "I am here!",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                        ),
                        onPressed: _goNext,
                        icon: const Icon(Icons.arrow_forward, size: 18),
                        label: const Text("Next"),
                        iconAlignment: IconAlignment.end,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
