import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'city_coupons_screen.dart';
import '../../services/coupon_service.dart'; 

class MyCitiesPage extends StatefulWidget {
  const MyCitiesPage({super.key});

  @override
  State<MyCitiesPage> createState() => _MyCitiesPageState();
}

class _MyCitiesPageState extends State<MyCitiesPage> {
  final TextEditingController _cityController = TextEditingController();
  String? _partnerId;
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _getPartnerId();
  }


  Future<void> _getPartnerId() async {
    final prefs = await SharedPreferences.getInstance();
    final isPartner = prefs.getBool('isPartner') ?? false;

    final id = isPartner
        ? prefs.getString('current_partner')
        : prefs.getString('current_user');

    if (mounted) {
      setState(() {
        _partnerId = id;
        _isLoadingUser = false;
      });
    }
  }


  Future<void> _deleteCity(String docId, String cityName) async {
    
    await CouponService.deletePartnerCityAndCoupons(cityName);

    
    await FirebaseFirestore.instance.collection('partner_cities').doc(docId).delete();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("City and its coupons deleted.")),
      );
    }
  }

  Future<void> _addCityToFirebase(String cityName) async {
    if (_partnerId == null) return;

    await FirebaseFirestore.instance.collection('partner_cities').add({
      'name': cityName,
      'partner_id': _partnerId,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  void _showAddCityDialog() {
    _cityController.clear();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFEBF4F6),
          title: const Text("Add New City", style: TextStyle(color: Color(0xFF0D2C54))),
          content: TextField(
            controller: _cityController,
            decoration: const InputDecoration(
              hintText: "Enter city name",
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3E4C63)),
              onPressed: () {
                if (_cityController.text.isNotEmpty) {
                  _addCityToFirebase(_cityController.text);
                  Navigator.pop(context);
                }
              },
              child: const Text("Add", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    
    if (_isLoadingUser) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    
    if (_partnerId == null) {
      return const Scaffold(
        body: Center(child: Text("Error: Not logged in correctly.")),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFEBF4F6),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 20),
                const Center(
                  child: Text(
                    "My Cities",
                    style: TextStyle(
                      fontSize: 28,
                      fontFamily: 'serif',
                      color: Color(0xFF0D2C54),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('partner_cities')
                        .where('partner_id', isEqualTo: _partnerId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final docs = snapshot.data?.docs ?? [];

                      if (docs.isEmpty) {
                        return const Center(child: Text("No cities added yet."));
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data = docs[index].data() as Map<String, dynamic>;
                          final cityName = data['name'] ?? 'Unknown';
                          final docId = docs[index].id;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 15),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        CityCouponsPage(cityName: cityName),
                                  ),
                                );
                              },
                              child: Container(
                                height: 50,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF9E8484),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          color: Colors.black54),
                                      
                                      onPressed: () => _deleteCity(docId, cityName),
                                    ),
                                    Container(
                                      width: 1,
                                      height: 30,
                                      color: Colors.black12,
                                    ),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: Text(
                                        cityName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),

          
            Positioned(
              right: 20,
              bottom: 100,
              child: GestureDetector(
                onTap: _showAddCityDialog,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 2),
                    color: Colors.transparent,
                  ),
                  child: const Icon(Icons.add, size: 30, color: Colors.black),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}