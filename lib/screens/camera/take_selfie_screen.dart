// take_selfie_screen.dart
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:typed_data';

import '../../globals.dart';
import '../rewards/congratulations_screen.dart';
import '../../services/coupon_service.dart';
import '../rewards/rewards_storage.dart';

class TakeSelfiePage extends StatefulWidget {
  final String cityName;
  final String attractionName;

  const TakeSelfiePage({
    super.key,
    required this.cityName,
    required this.attractionName,
  });

  @override
  State<TakeSelfiePage> createState() => _TakeSelfiePageState();
}

class _TakeSelfiePageState extends State<TakeSelfiePage> {
  CameraController? _controller;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      if (cameras.isEmpty) {
        cameras = await availableCameras();
      }
      if (cameras.isEmpty) return;

      CameraDescription camera = cameras.first;
      for (var cam in cameras) {
        if (cam.lensDirection == CameraLensDirection.front) {
          camera = cam;
          break;
        }
      }

      _controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _controller!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Camera error: $e");
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_isSaving) return;
    if (_controller == null || !_controller!.value.isInitialized) return;

    setState(() => _isSaving = true);

    try {
      final cityName = widget.cityName.trim();
      final attractionName = widget.attractionName.trim();

      
      final XFile image = await _controller!.takePicture();
      final Uint8List imageBytes = await image.readAsBytes();

      
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('current_user');

      if (username == null || username.trim().isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to save your photos.'),
            duration: Duration(seconds: 2),
          ),
        );
        setState(() => _isSaving = false);
        return;
      }


      await FirebaseFirestore.instance
          .collection('travellers')
          .doc(username)
          .set(
        {'unlocked_cities': FieldValue.arrayUnion([cityName])},
        SetOptions(merge: true),
      );

      
      final ts = DateTime.now().millisecondsSinceEpoch;
      final String fileName = "$ts.jpg";
      final Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('user_photos/$username/$cityName/$fileName');

      await storageRef.putData(
        imageBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final String downloadUrl = await storageRef.getDownloadURL();

    
      await FirebaseFirestore.instance
          .collection('travellers')
          .doc(username)
          .collection('cities')
          .doc(cityName)
          .collection('photos')
          .doc(ts.toString())
          .set({
        'url': downloadUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

     
      if (cityName == 'Athens') {
        await FirebaseFirestore.instance
            .collection('travellers')
            .doc(username)
            .set({
          'athens_gallery': FieldValue.arrayUnion([downloadUrl]),
        }, SetOptions(merge: true));
      }

      
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CongratulationsPage(
            cityName: cityName,
            attractionName: attractionName,
          ),
        ),
      );
    } catch (e) {
      debugPrint("Critical Error: $e");
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(_controller!),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 40),
                const Text(
                  "Take a selfie to\nremember!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D2C54),
                    fontFamily: 'serif',
                    shadows: [Shadow(color: Colors.white, blurRadius: 10)],
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _isSaving ? null : _takePicture,
                  child: Opacity(
                    opacity: _isSaving ? 0.5 : 1,
                    child: Container(
                      height: 80,
                      width: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0C0E0),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 10)
                        ],
                      ),
                      child: _isSaving
                          ? const Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(),
                            )
                          : const Icon(Icons.camera_alt,
                              color: Colors.black, size: 35),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
          Positioned(
            top: 40,
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.white54,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: _isSaving ? null : () => Navigator.pop(context),
              ),
            ),
          ),
          if (_isSaving)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Text("Saving...", style: TextStyle(color: Colors.white)),
              ),
            )
        ],
      ),
    );
  }
}
