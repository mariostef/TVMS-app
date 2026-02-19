// file_home_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FileHomePage extends StatefulWidget {
  const FileHomePage({super.key});

  @override
  State<FileHomePage> createState() => FileHomePageState();
}

class FileHomePageState extends State<FileHomePage> {
  bool _athensUnlocked = false;
  String? _username;
  List<String> _athensCloudPhotos = const [];

  @override
  void initState() {
    super.initState();
    _loadUnlocks();
  }

  Future<void> refresh() async {
    await _loadUnlocks();
  }

  Future<void> _loadUnlocks() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('current_user');

    bool athensUnlocked = false;
    List<String> athensCloudPhotos = const [];

    if (username != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('travellers').doc(username).get();
        final data = doc.data();
        final unlockedCities =
            (data?['unlocked_cities'] as List?)?.cast<String>() ?? const <String>[];
        athensUnlocked = unlockedCities.contains('Athens');

        try {
          final q = await FirebaseFirestore.instance
              .collection('travellers')
              .doc(username)
              .collection('cities')
              .doc('Athens')
              .collection('photos')
              .orderBy('createdAt', descending: false)
              .get();

          athensCloudPhotos = q.docs
              .map((d) => (d.data()['url'] ?? '').toString())
              .where((u) => u.isNotEmpty)
              .toList();
        } catch (_) {
          athensCloudPhotos = const <String>[];
        }

        final legacy =
            (data?['athens_gallery'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[];
        if (athensCloudPhotos.isEmpty && legacy.isNotEmpty) {
          athensCloudPhotos = legacy;
        }
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() {
      _username = username;
      _athensUnlocked = athensUnlocked;
      _athensCloudPhotos = athensCloudPhotos;
    });
  }

  Future<void> _openAthensIfUnlocked() async {
    if (_username == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please log in to view your photos.")),
      );
      return;
    }

    final unlocked = _athensUnlocked;

    if (!unlocked) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Athens is locked. Take a photo there first!")),
      );
      return;
    }

    final photos = <String>[..._athensCloudPhotos];

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AthensGalleryPage(photoEntries: photos),
      ),
    );
  }

  Widget _cityButton({
    required String name,
    required bool unlocked,
    required VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: SizedBox(
        height: 34,
        child: ElevatedButton(
          onPressed: unlocked ? onTap : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8E7B7B),
            disabledBackgroundColor: const Color(0xFF8E7B7B).withOpacity(0.35),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                unlocked ? Icons.lock_open : Icons.lock,
                size: 16,
                color: Colors.black.withOpacity(unlocked ? 0.9 : 0.45),
              ),
              const SizedBox(width: 10),
              Text(
                name,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black.withOpacity(unlocked ? 0.9 : 0.45),
                  fontFamily: 'serif',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFEBF4F6),
      width: double.infinity,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
          child: ListView(
            children: [
              const SizedBox(height: 8),
              const Text(
                "File",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0D2C54),
                  fontFamily: 'serif',
                ),
              ),
              const SizedBox(height: 22),
              _cityButton(
                name: "Athens",
                unlocked: _athensUnlocked,
                onTap: _openAthensIfUnlocked,
              ),
              _cityButton(name: "Paris", unlocked: false, onTap: null),
              _cityButton(name: "Rome", unlocked: false, onTap: null),
              _cityButton(name: "New York", unlocked: false, onTap: null),
              _cityButton(name: "Milan", unlocked: false, onTap: null),
              _cityButton(name: "Stockholm", unlocked: false, onTap: null),
              _cityButton(name: "Brussels", unlocked: false, onTap: null),
              _cityButton(name: "Lille", unlocked: false, onTap: null),
              _cityButton(name: "Bilbao", unlocked: false, onTap: null),
              const SizedBox(height: 18),
              Text(
                "Your map isn't full yet, discover\nmore cities.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black.withOpacity(0.55),
                  fontFamily: 'serif',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AthensGalleryPage extends StatefulWidget {
  final List<String> photoEntries;
  const AthensGalleryPage({super.key, required this.photoEntries});

  @override
  State<AthensGalleryPage> createState() => _AthensGalleryPageState();
}

class _AthensGalleryPageState extends State<AthensGalleryPage> {
  late final PageController _pageController;
  final int _virtualStart = 10000;

  @override
  void initState() {
    super.initState();
    final len = widget.photoEntries.length;
    final initial = (len == 0) ? 0 : _virtualStart - (_virtualStart % len);
    _pageController = PageController(initialPage: initial);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildPhoto(String entry) {
    if (entry.startsWith('http://') || entry.startsWith('https://')) {
      return Image.network(
        entry,
        fit: BoxFit.cover,
        loadingBuilder: (ctx, child, progress) {
          if (progress == null) return child;
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        },
        errorBuilder: (_, __, ___) => Center(
          child: Text(
            "Could not load photo\n$entry",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black.withOpacity(0.65)),
          ),
        ),
      );
    }

    return Center(
      child: Text(
        "Could not load photo\n$entry",
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.black.withOpacity(0.65)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEBF4F6),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            const Text(
              "Athens",
              style: TextStyle(
                fontSize: 22,
                color: Color(0xFF0D2C54),
                fontFamily: 'serif',
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: widget.photoEntries.isEmpty
                  ? Center(
                      child: Text(
                        "No photos yet.\nTake your first selfie in Athens!",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black.withOpacity(0.6)),
                      ),
                    )
                  : PageView.builder(
                      controller: _pageController,
                      itemBuilder: (context, index) {
                        final len = widget.photoEntries.length;
                        final realIndex = index % len;
                        final entry = widget.photoEntries[realIndex];

                        return Padding(
                          padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              color: Colors.black12,
                              child: _buildPhoto(entry),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
