import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PartnerSubscriptionPage extends StatefulWidget {
  const PartnerSubscriptionPage({super.key});

  @override
  State<PartnerSubscriptionPage> createState() => _PartnerSubscriptionPageState();
}

class _PartnerSubscriptionPageState extends State<PartnerSubscriptionPage> {
  
  String currentPlan = "package"; 
  int totalCoupons = 0;
  
  String? _partnerId; 

  
  int? selectedPackageIndex;

  final _cardNumberController = TextEditingController();
  final _cvvController = TextEditingController();
  final _expiryDateController = TextEditingController();
  bool _agreedToTerms = false;

  final List<String> packages = [
    "Package 1: 50 codes • 1 month €10",
    "Package 2: 60 codes • 2 months €12",
    "Package 3: 70 codes • 3 months €13",
    "Package 4: 80 codes • 6 months €14,5",
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedPlan(); 
  }

 
  Future<void> _loadSavedPlan() async {
    final prefs = await SharedPreferences.getInstance();
    
   
    final partner = prefs.getString('current_partner'); 
    
    setState(() {
      _partnerId = partner;

      if (prefs.containsKey('current_plan_name')) {
        currentPlan = prefs.getString('current_plan_name')!;
        totalCoupons = prefs.getInt('current_plan_total') ?? 50; 
      }

      
      selectedPackageIndex = prefs.getInt('selected_package_index');
    });

   
    if (partner != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('partners').doc(partner).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          final cloudTotal = data['plan_total'];
          if (cloudTotal != null && cloudTotal is int) {
             setState(() {
               totalCoupons = cloudTotal;
             });
           
             await prefs.setInt('current_plan_total', cloudTotal);
          }
        }
      } catch (e) {
        debugPrint("Error syncing plan total: $e");
      }
    }
  }

  Widget _buildPackageButton(int index, String text) {
    bool isSelected = selectedPackageIndex == index;
    return GestureDetector(
      onTap: () async {
       
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('selected_package_index', index);

        setState(() {
          selectedPackageIndex = index;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3E4C63) : const Color(0xFF6C829F),
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildInput(String hint, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white70),
          filled: true,
          fillColor: const Color(0xFF6C829F),
          suffixIcon: const Icon(Icons.cancel_outlined, color: Colors.white70),
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEBF4F6),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(
                child: Text(
                  "Subscription",
                  style: TextStyle(fontSize: 28, fontFamily: 'serif', color: Color(0xFF0D2C54)),
                ),
              ),
              const SizedBox(height: 30),

              const Text("My current plan:", style: TextStyle(fontSize: 16, color: Color(0xFF2C3E50))),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C829F),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    currentPlan.isEmpty ? "No active plan" : currentPlan,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              
              StreamBuilder<QuerySnapshot>(
                stream: _partnerId == null 
                    ? const Stream.empty() 
                    : FirebaseFirestore.instance
                        .collection('city_coupons')
                        .where('partnerId', isEqualTo: _partnerId)
                        .snapshots(),
                builder: (context, snapshot) {
                  
                  int realUsed = 0;
                  if (snapshot.hasData) {
                    realUsed = snapshot.data!.docs.length;
                  }
                  
                  
                  double percent = totalCoupons > 0 ? (realUsed / totalCoupons) : 0.0;
                  if (percent > 1.0) percent = 1.0;

                  return Column(
                    children: [
                      Center(
                        child: Text(
                          "$realUsed/$totalCoupons coupons are used", 
                          style: const TextStyle(color: Color(0xFF0D2C54), fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: LinearProgressIndicator(
                          value: percent,
                          backgroundColor: Colors.grey[300],
                          color: percent >= 1.0 ? Colors.red : const Color(0xFF3E4C63),
                          minHeight: 5,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      )
                    ],
                  );
                },
              ),
              
              const SizedBox(height: 30),

              const Text("Change plan:", style: TextStyle(fontSize: 16, color: Color(0xFF2C3E50))),
              const SizedBox(height: 10),
              ...List.generate(packages.length, (index) => _buildPackageButton(index, packages[index])),

              const Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: EdgeInsets.only(top: 5),
                  child: Text("Suggested package", style: TextStyle(fontSize: 10)),
                ),
              ),
              const SizedBox(height: 20),

              const Text("Card details:", style: TextStyle(fontSize: 16, color: Color(0xFF2C3E50))),
              const SizedBox(height: 10),
              _buildInput("Card Number*", _cardNumberController),
              _buildInput("CVV*", _cvvController),
              _buildInput("Expire Date*", _expiryDateController),

              const SizedBox(height: 10),

              Row(
                children: [
                  Checkbox(
                    value: _agreedToTerms,
                    activeColor: const Color(0xFF3E4C63),
                    onChanged: (val) => setState(() => _agreedToTerms = val ?? false),
                  ),
                  const Expanded(
                    child: Text(
                      "I agree to the terms and conditions.",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3E4C63),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                  ),
                  onPressed: () async {
                    if (_agreedToTerms && selectedPackageIndex != null) {
                      String newPlanName = "Package ${selectedPackageIndex! + 1}";
                      int newTotal = 50 + (selectedPackageIndex! * 10);

                      final prefs = await SharedPreferences.getInstance();
                      
                      
                      final partnerId = prefs.getString('current_partner'); 

                     
                      await prefs.setString('current_plan_name', newPlanName);
                      await prefs.setInt('current_plan_total', newTotal);
                      await prefs.setInt('current_plan_used', 0); 

                      
                      if (partnerId != null && partnerId.isNotEmpty) {
                        await FirebaseFirestore.instance
                            .collection('partners')
                            .doc(partnerId)
                            .set({
                          'plan_name': newPlanName,
                          'plan_total': newTotal,
                          
                          'updatedAt': FieldValue.serverTimestamp(),
                        }, SetOptions(merge: true));
                      }

                      setState(() {
                        currentPlan = newPlanName;
                        totalCoupons = newTotal;
                       
                      });

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Subscription Updated!")),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please select a package and agree to terms")),
                      );
                    }
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check, color: Colors.white),
                      SizedBox(width: 10),
                      Text("Pay", style: TextStyle(color: Colors.white, fontSize: 16)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}