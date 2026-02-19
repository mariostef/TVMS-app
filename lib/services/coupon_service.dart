import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';


import '../screens/rewards/rewards_storage.dart';

class CouponService {
 
  static Future<String?> pickRandomCoupon(String city) async {
    final db = FirebaseFirestore.instance;

    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('current_user');
      if (username == null) return null;

      final cityTrimmed = city.trim();

      String userGender = 'Unknown';
      String userAgeGroup = 'All ages';

      final userDoc = await db.collection('travellers').doc(username).get();
      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data()!;
        userGender = (data['gender'] ?? 'Unknown').toString();

        final birthYearRaw = data['birth_year'];
        int birthYear = 0;
        if (birthYearRaw is int) birthYear = birthYearRaw;
        if (birthYearRaw is num) birthYear = birthYearRaw.toInt();
        if (birthYearRaw is String) birthYear = int.tryParse(birthYearRaw) ?? 0;

        if (birthYear > 0) {
          final currentYear = DateTime.now().year;
          final age = currentYear - birthYear;
          if (age < 20) {
            userAgeGroup = '<20';
          } else if (age <= 30) {
            userAgeGroup = '20-30';
          } else {
            userAgeGroup = '>30';
          }
        }
      }

      
      final alreadyUnlocked = await RewardsStorage.loadUnlockedCoupons(cityTrimmed, username);

      final snapshot = await db
          .collection('city_coupons')
          .where('city', isEqualTo: cityTrimmed)
         
          .get();

      if (snapshot.docs.isEmpty) return null;

      final validDocs = snapshot.docs.where((doc) {
        final data = doc.data();
        final code = (data['code'] ?? '').toString().trim();
        if (code.isEmpty) return false;

        final targetGender = (data['target_gender'] ?? 'Both').toString();
        final targetAge = (data['target_age'] ?? 'All ages').toString();

        final genderMatch =
            (targetGender == 'Both') || (userGender == 'Unknown') || (targetGender == userGender);

        final ageMatch = (targetAge == 'All ages') || (targetAge == userAgeGroup);

        final notAlreadyUnlocked = !alreadyUnlocked.contains(code);

        return genderMatch && ageMatch && notAlreadyUnlocked;
      }).toList();

      if (validDocs.isEmpty) return null;

      final selectedDoc = validDocs[Random().nextInt(validDocs.length)];
      final selectedCode = (selectedDoc.get('code') as String).trim();

    
      return selectedCode;
    } catch (_) {
      return null;
    }
  }


  static Future<String?> _currentPartnerId() async {
    final prefs = await SharedPreferences.getInstance();
    final isPartner = prefs.getBool('isPartner') ?? false;
    if (!isPartner) return null;

   
    return prefs.getString('current_partner');
  }

 
  static Future<void> createOrResetPartnerCity(String city) async {
    final db = FirebaseFirestore.instance;
    final partnerId = await _currentPartnerId();
    if (partnerId == null) return;

    await db.collection('partners').doc(partnerId).set({
      'cities': FieldValue.arrayUnion([city]),
    }, SetOptions(merge: true));

    await deleteAllPartnerCouponsForCity(city);
  }

  
  static Future<void> deletePartnerCityAndCoupons(String city) async {
    final db = FirebaseFirestore.instance;
    final partnerId = await _currentPartnerId();
    if (partnerId == null) return;

    await db.collection('partners').doc(partnerId).set({
      'cities': FieldValue.arrayRemove([city]),
    }, SetOptions(merge: true));

    await deleteAllPartnerCouponsForCity(city);
  }

 
  static Future<void> deleteAllPartnerCouponsForCity(String city) async {
    final db = FirebaseFirestore.instance;
    final partnerId = await _currentPartnerId();
    if (partnerId == null) return;

    Query<Map<String, dynamic>> query = db
        .collection('city_coupons')
        .where('city', isEqualTo: city)
        .where('partnerId', isEqualTo: partnerId)
        .limit(450);

    while (true) {
      final snap = await query.get();
      if (snap.docs.isEmpty) break;

      final batch = db.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }
}
