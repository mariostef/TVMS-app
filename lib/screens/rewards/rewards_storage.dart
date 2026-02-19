import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RewardsStorage {
  static String _keyCoupons(String city, String username) => '${username}_${city}_unlocked_coupons';
  static String _keyBonus(String city, String username) => '${username}_${city}_bonus_unlocked';
  static const String _sep = '||';

  static final StreamController<_RewardsChanged> _controller =
      StreamController<_RewardsChanged>.broadcast();

  static Stream<_RewardsChanged> get changes => _controller.stream;

  static void _notifyChanged(String city, String username) {
    _controller.add(_RewardsChanged(city.trim(), username.trim()));
  }

  static String extractCode(String entry) {
    final parts = entry.split(_sep);
    return (parts.isNotEmpty ? parts.first : entry).trim();
  }

  static String toDisplayText(String entry) {
    return entry.replaceAll(_sep, '  ').trim();
  }

 
  static Future<void> syncWithCloud(String city, String username) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('travellers').doc(username).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        
        final cloudCoupons = List<String>.from(data['${city}_coupons'] ?? []);
        
        if (cloudCoupons.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
        
          await prefs.setStringList(_keyCoupons(city, username), cloudCoupons);
        }
      }
    } catch (e) {
      print("Cloud sync error: $e");
    }
  }

  static Future<Set<String>> loadUnlockedCoupons(String city, String username) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_keyCoupons(city, username)) ?? <String>[];
    return list.toSet();
  }

 
  static Future<void> saveUnlockedCoupons(String city, String username, Set<String> coupons) async {
    final list = coupons.toList();
    
   
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyCoupons(city, username), list);


    try {
      await FirebaseFirestore.instance.collection('travellers').doc(username).set({
        '${city}_coupons': list, 
      }, SetOptions(merge: true));
    } catch (e) {
      print("Failed to save to cloud: $e");
    }

    _notifyChanged(city, username);
  }

  static Future<void> unlockCoupons(String city, String username, List<String> couponsToUnlock) async {
    final unlocked = await loadUnlockedCoupons(city, username);
    unlocked.addAll(couponsToUnlock);
    await saveUnlockedCoupons(city, username, unlocked);
  }

  static Future<void> syncDeletedCoupons(String city, String username) async {
    final unlocked = await loadUnlockedCoupons(city, username);
    if (unlocked.isEmpty) return;

    final db = FirebaseFirestore.instance;
    final toRemove = <String>{};

    for (final entry in unlocked) {
      final code = extractCode(entry);
      if (code.isEmpty) {
        toRemove.add(entry);
        continue;
      }

      final q = await db
          .collection('city_coupons')
          .where('city', isEqualTo: city)
          .where('code', isEqualTo: code)
          .limit(1)
          .get();

      if (q.docs.isEmpty) {
        toRemove.add(entry);
      }
    }

    if (toRemove.isNotEmpty) {
      unlocked.removeAll(toRemove);
      await saveUnlockedCoupons(city, username, unlocked);
    }
  }

  static Future<bool> loadBonusUnlocked(String city, String username) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyBonus(city, username)) ?? false;
  }

  static Future<void> setBonusUnlocked(String city, String username, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBonus(city, username), value);
    _notifyChanged(city, username);
  }
}

class _RewardsChanged {
  final String city;
  final String username;
  _RewardsChanged(this.city, this.username);
}