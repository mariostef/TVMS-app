import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CityCouponsPage extends StatefulWidget {
  final String cityName;

  const CityCouponsPage({super.key, required this.cityName});

  @override
  State<CityCouponsPage> createState() => _CityCouponsPageState();
}

class _CityCouponsPageState extends State<CityCouponsPage> {
  final TextEditingController _couponController = TextEditingController();
  String? _partnerName;

  int _totalLimit = 50;

  String _selectedGender = 'Both';
  String _selectedAge = 'All ages';

  final List<String> genderOptions = ['Female', 'Male', 'Both'];
  final List<String> ageOptions = ['<20', '20-30', '>30', 'All ages'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _partnerName = prefs.getString('current_partner') ?? "UnknownPartner";
      _totalLimit = prefs.getInt('current_plan_total') ?? 50;
    });
  }

  Future<void> _uploadToCloud() async {
    if (_partnerName == null) return;

    final code = _couponController.text.trim();
    final city = widget.cityName.trim();

    if (code.isEmpty) return;

    try {
      await FirebaseFirestore.instance.collection('city_coupons').add({
        'code': code,
        'city': city,
        'partner': _partnerName,
        'partnerId': _partnerName,
        'isRedeemed': false,
        'createdAt': FieldValue.serverTimestamp(),
        'target_gender': _selectedGender,
        'target_age': _selectedAge,
      });

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: Colors.green, content: Text("✅ Coupon added!")),
      );
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  Future<void> _deleteFromCloud(String docId) async {
    await FirebaseFirestore.instance.collection('city_coupons').doc(docId).delete();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Coupon removed"), duration: Duration(milliseconds: 500)),
      );
    }
  }

  Future<void> _editCouponInCloud(String docId, String newCode) async {
    try {
      await FirebaseFirestore.instance.collection('city_coupons').doc(docId).update({'code': newCode});
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint("Edit Error: $e");
    }
  }

  Future<void> _updateLocalUsage(int currentCount) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('partner_used_coupons', currentCount);
  }

  void _showAddDialog(int usedTotal) {
    
    if (usedTotal >= _totalLimit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Limit Reached! Upgrade your plan to add more."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _couponController.clear();
    setState(() {
      _selectedGender = 'Both';
      _selectedAge = 'All ages';
    });

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFFEBF4F6),
              title: const Text("Add Targeted Coupon", style: TextStyle(color: Color(0xFF0D2C54))),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _couponController,
                    decoration: const InputDecoration(
                      hintText: "Enter coupon code",
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Target Gender:", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(5)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedGender,
                        isExpanded: true,
                        items: genderOptions.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value, style: const TextStyle(color: Color(0xFF0D2C54))),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setDialogState(() => _selectedGender = newValue!);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Target Age:", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(5)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedAge,
                        isExpanded: true,
                        items: ageOptions.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value, style: const TextStyle(color: Color(0xFF0D2C54))),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setDialogState(() => _selectedAge = newValue!);
                        },
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3E4C63)),
                  onPressed: () {
                    if (_couponController.text.isNotEmpty) {
                      _uploadToCloud();
                    }
                  },
                  child: const Text("Save", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditDialog(String docId, String currentCode) {
    _couponController.text = currentCode;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFEBF4F6),
        title: const Text("Edit Coupon Name", style: TextStyle(color: Color(0xFF0D2C54))),
        content: TextField(
          controller: _couponController,
          decoration: const InputDecoration(filled: true, fillColor: Colors.white),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (_couponController.text.isNotEmpty) {
                _editCouponInCloud(docId, _couponController.text);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3E4C63)),
            child: const Text("Update", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_partnerName == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final city = widget.cityName.trim();

    final usedTotalStream = FirebaseFirestore.instance
        .collection('city_coupons')
        .where('partnerId', isEqualTo: _partnerName)
        .snapshots();

    final activeCityStream = FirebaseFirestore.instance
        .collection('city_coupons')
        .where('city', isEqualTo: city)
        .where('isRedeemed', isEqualTo: false)
        .where('partnerId', isEqualTo: _partnerName)
        .snapshots();

    return Scaffold(
      backgroundColor: const Color(0xFFEBF4F6),
      body: SafeArea(
        child: Stack(
          children: [
            StreamBuilder<QuerySnapshot>(
              stream: usedTotalStream,
              builder: (context, usedSnap) {
                if (!usedSnap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final usedTotal = usedSnap.data!.docs.length;
                _updateLocalUsage(usedTotal);

                return Column(
                  children: [
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        widget.cityName,
                        style: const TextStyle(
                          fontSize: 32,
                          fontFamily: 'serif',
                          color: Color(0xFF0D2C54),
                        ),
                      ),
                    ),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: activeCityStream,
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                          final docs = snapshot.data!.docs;

                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF3E4C63),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    "Used Coupons: $usedTotal / $_totalLimit",
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              if (docs.isEmpty)
                                const Expanded(child: Center(child: Text("No active coupons found.")))
                              else
                                Expanded(
                                  child: ListView.builder(
                                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                                    itemCount: docs.length,
                                    itemBuilder: (context, index) {
                                      final data = docs[index].data() as Map<String, dynamic>;
                                      final code = data['code'] ?? '';
                                      final docId = docs[index].id;

                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 15),
                                        child: Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit, size: 20, color: Colors.black87),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                              onPressed: () => _showEditDialog(docId, code),
                                            ),
                                            const SizedBox(width: 15),
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline, size: 20, color: Colors.black87),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                              onPressed: () => _deleteFromCloud(docId),
                                            ),
                                            const SizedBox(width: 15),
                                            Expanded(
                                              child: Container(
                                                height: 45,
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF9E8484),
                                                  borderRadius: BorderRadius.circular(5),
                                                ),
                                                child: Text(
                                                  code,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
            Positioned(
              left: 20,
              bottom: 30,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C829F),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                ),
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
                label: const Text("Back", style: TextStyle(color: Colors.white)),
              ),
            ),
            
           
            Positioned(
              right: 20,
              bottom: 30,
              child: StreamBuilder<QuerySnapshot>(
                stream: usedTotalStream,
                builder: (context, snapshot) {
                  int usedTotal = 0;
                  if (snapshot.hasData) usedTotal = snapshot.data!.docs.length;

                  return GestureDetector(
                    onTap: () {
                     
                      if (usedTotal >= _totalLimit) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "Limit reached ($_totalLimit). Delete old coupons or Upgrade your plan.",
                              style: const TextStyle(color: Colors.white),
                            ),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                        return; 
                      }

                     
                      _showAddDialog(usedTotal);
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 2),
                        color: usedTotal >= _totalLimit 
                            ? Colors.grey 
                            : Colors.transparent,
                      ),
                      child: Icon(
                        Icons.add, 
                        size: 30, 
                        color: usedTotal >= _totalLimit ? Colors.white : Colors.black
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