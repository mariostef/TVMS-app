import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CityGalleryPage extends StatefulWidget {
  final String cityName; 
  const CityGalleryPage({super.key, required this.cityName});

  @override
  State<CityGalleryPage> createState() => _CityGalleryPageState();
}

class _CityGalleryPageState extends State<CityGalleryPage> {
  String? _username;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('current_user');
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_username == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.cityName} Gallery"),
        backgroundColor: const Color(0xFF0D2C54),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFEBF4F6),
      
     
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('travellers').doc(_username).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final data = snapshot.data!.data() as Map<String, dynamic>?;
          
          final fieldName = '${widget.cityName.toLowerCase()}_gallery';
          
          final List<dynamic> photoUrls = data?[fieldName] ?? [];

          if (photoUrls.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.photo_library_outlined, size: 60, color: Colors.grey),
                  const SizedBox(height: 10),
                  Text("No photos in ${widget.cityName} yet.", style: const TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(10),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, // 3 φωτογραφίες ανά σειρά
              crossAxisSpacing: 5,
              mainAxisSpacing: 5,
            ),
            itemCount: photoUrls.length,
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  photoUrls[index], // Το URL από το Firebase
                  fit: BoxFit.cover,
                  loadingBuilder: (ctx, child, progress) {
                    if (progress == null) return child;
                    return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}