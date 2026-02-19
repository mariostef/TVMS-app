import 'package:flutter/material.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'rewards_storage.dart';

class CongratulationsPage extends StatefulWidget {
  final String attractionName;
  final String cityName;

  const CongratulationsPage({
    super.key,
    required this.attractionName,
    required this.cityName,
  });

  @override
  State<CongratulationsPage> createState() => _CongratulationsPageState();
}

class _CongratulationsPageState extends State<CongratulationsPage> {
  int visitedCount = 0;
  int totalAttractions = 6;
  double progress = 0.0;

  List<Map<String, String>> earnedRewards = [];
  bool isLoading = true;
  String statusMessage = "Updating progress & unlocking rewards...";

  int? _focusedIndex;

  @override
  void initState() {
    super.initState();
    _processVisitAndRewards();
  }

  Future<void> _processVisitAndRewards() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('current_user');

      if (username == null) {
        if (!mounted) return;
        setState(() {
          isLoading = false;
          statusMessage = "Please login to track progress.";
        });
        return;
      }

      final userRef = FirebaseFirestore.instance.collection('travellers').doc(username);

      final city = widget.cityName.trim();
      final attraction = widget.attractionName.trim();
      final visitId = "${city}_$attraction";

      final userDocBefore = await userRef.get();
      if (!userDocBefore.exists) {
        if (!mounted) return;
        setState(() {
          isLoading = false;
          statusMessage = "User not found.";
        });
        return;
      }

      final dataBefore = userDocBefore.data();
      final allUnlocksBefore = List<String>.from(
        (dataBefore?['unlocked_attractions'] as List?)?.map((e) => e.toString()).toList() ??
            const <String>[],
      );

      final alreadyVisited = allUnlocksBefore.contains(visitId);

      if (!alreadyVisited) {
        await userRef.update({
          'unlocked_attractions': FieldValue.arrayUnion([visitId])
        });
      }

      final allUnlocks = <String>[...allUnlocksBefore];
      if (!allUnlocks.contains(visitId)) {
        allUnlocks.add(visitId);
      }

      final cityUnlocks = allUnlocks.where((u) => u.startsWith("${city}_")).toList();
      String userGender = (dataBefore?['gender'] ?? 'Unknown').toString();

      if (mounted) {
        setState(() {
          visitedCount = cityUnlocks.length;
          if (totalAttractions > 0) {
            progress = (visitedCount / totalAttractions) * 100;
            if (progress > 100) progress = 100;
          }
        });
      }

      if (alreadyVisited) {
        if (!mounted) return;
        setState(() {
          earnedRewards = [];
          isLoading = false;
          statusMessage = "You have already visited this destination.";
        });
        return;
      }

      await _fetchTargetedCoupons(userGender, username);
    } catch (e) {
      debugPrint("Error: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
          statusMessage = "Error: $e";
        });
      }
    }
  }

  Future<void> _fetchTargetedCoupons(String gender, String username) async {
    final city = widget.cityName.trim();

    final alreadyUnlockedRaw = await RewardsStorage.loadUnlockedCoupons(city, username);
    final alreadyUnlockedCodes = alreadyUnlockedRaw
        .map((e) => RewardsStorage.extractCode(e))
        .where((c) => c.isNotEmpty)
        .toSet();

    final snapshot = await FirebaseFirestore.instance
        .collection('city_coupons')
        .where('city', isEqualTo: city)
        .where('isRedeemed', isEqualTo: false)
        .get();

    if (snapshot.docs.isEmpty) {
      if (mounted) setState(() => isLoading = false);
      return;
    }

    final validDocs = snapshot.docs.where((doc) {
      final data = doc.data();
      final targetGender = data['target_gender'] ?? 'Both';
      final code = (data['code'] ?? '').toString().trim();

      final genderMatch =
          (targetGender == 'Both') || (gender == 'Unknown') || (targetGender == gender);

      final notAlreadyUnlocked = code.isNotEmpty && !alreadyUnlockedCodes.contains(code);

      return genderMatch && notAlreadyUnlocked;
    }).toList();

    if (validDocs.isEmpty) {
      if (mounted) {
        setState(() {
          isLoading = false;
          statusMessage = "No new coupons available for you right now.";
        });
      }
      return;
    }

    final countToPick = min(2, validDocs.length);
    final rnd = Random();

    final pickedIndices = <int>{};
    while (pickedIndices.length < countToPick) {
      pickedIndices.add(rnd.nextInt(validDocs.length));
    }

    final tempRewards = <Map<String, String>>[];
    final newStoredEntries = <String>[];

    for (final i in pickedIndices) {
      final doc = validDocs[i];
      final code = (doc.data()['code'] ?? '').toString().trim();
      final partner =
          doc.data().containsKey('partner') ? doc.data()['partner'].toString().trim() : "Partner";
      if (code.isEmpty) continue;

      tempRewards.add({'text': code});

      newStoredEntries.add("$code||$partner");
    }

    if (newStoredEntries.isNotEmpty) {
      final updated = await RewardsStorage.loadUnlockedCoupons(city, username);
      updated.addAll(newStoredEntries);
      await RewardsStorage.saveUnlockedCoupons(city, username, updated);
    }

    if (mounted) {
      setState(() {
        earnedRewards = tempRewards;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _focusedIndex = null;
        });
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFEBF4F6),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 40),
                Text(
                  "Congratulations, you’ve\nreached the ${widget.attractionName}!",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontFamily: 'serif',
                    color: Color(0xFF0D2C54),
                    fontWeight: FontWeight.normal,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 50),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        value: progress / 100,
                        strokeWidth: 2,
                        color: Colors.black87,
                        backgroundColor: Colors.grey[400],
                      ),
                    ),
                    const SizedBox(width: 15),
                    Text(
                      "You’ve completed ${progress.toInt()}% ($visitedCount/$totalAttractions) of your missions",
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'serif',
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 60),
                if (isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (earnedRewards.isEmpty)
                  Text(statusMessage, style: const TextStyle(fontFamily: 'serif'))
                else
                  Expanded(
                    child: ListView.builder(
                      itemCount: earnedRewards.length,
                      itemBuilder: (context, index) {
                        final reward = earnedRewards[index];

                        final isFocused = _focusedIndex == index;
                        final isDimmed = _focusedIndex != null && !isFocused;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (_focusedIndex == index) {
                                _focusedIndex = null;
                              } else {
                                _focusedIndex = index;
                              }
                            });
                          },
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 300),
                            opacity: isDimmed ? 0.5 : 1.0,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutBack,
                              transform: Matrix4.identity()..scale(isFocused ? 1.05 : 1.0),
                              transformAlignment: Alignment.center,
                              margin: EdgeInsets.only(
                                bottom: isFocused ? 35 : 25.0,
                                top: isFocused ? 10 : 0,
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.lock_open, color: Colors.black, size: 28),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      height: isFocused ? 100 : 90,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: isFocused
                                            ? const Color(0xFF0D2C54)
                                            : const Color(0xFF9E8484),
                                        borderRadius: BorderRadius.circular(isFocused ? 8 : 4),
                                        boxShadow: isFocused
                                            ? [
                                                const BoxShadow(
                                                  color: Colors.black26,
                                                  blurRadius: 10,
                                                  offset: Offset(0, 5),
                                                )
                                              ]
                                            : [],
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                        child: Text(
                                          reward['text']!.toUpperCase(),
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontFamily: 'sans-serif',
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                if (earnedRewards.isEmpty) const Spacer(),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 30),
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, size: 18),
                      label: const Text("Back"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C829F),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
