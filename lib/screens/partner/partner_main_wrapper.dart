import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
import '../auth/partner_login_screen.dart'; 
import 'my_cities_screen.dart';
import 'partner_subscription_screen.dart';

class PartnerMainWrapper extends StatefulWidget {
  const PartnerMainWrapper({super.key});

  @override
  State<PartnerMainWrapper> createState() => _PartnerMainWrapperState();
}

class _PartnerMainWrapperState extends State<PartnerMainWrapper> {
  int _currentTab = 1; 

  final List<Widget> _pages = [
    const MyCitiesPage(),
    const PartnerSubscriptionPage(),
  ];

 
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false); 
    await prefs.remove('current_user');
    
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const PartnerLoginPage()), 
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, 
      backgroundColor: const Color(0xFFEBF4F6),
      
      
      appBar: AppBar(
        backgroundColor: Colors.transparent, 
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _logout, 
            icon: const Icon(Icons.logout, color: Color(0xFF0D2C54)),
            tooltip: "Log Out",
          ),
          const SizedBox(width: 10), 
        ],
      ),

      body: _pages[_currentTab],

      
      floatingActionButton: SizedBox(
        width: 70, 
        height: 70,
        child: FloatingActionButton(
          onPressed: () {}, 
          backgroundColor: const Color(0xFF0D2C54), 
          elevation: 4.0, 
          shape: const CircleBorder(),
          child: Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/logo.png.png"), 
                fit: BoxFit.contain, 
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

     
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 20), 
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40), 
          child: BottomAppBar(
            padding: EdgeInsets.zero,
            color: const Color(0xFFF3EDF7), 
            elevation: 0,
            height: 80, 
            shape: const CircularNotchedRectangle(), 
            notchMargin: 8.0, 
            
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTabItem(index: 0, icon: Icons.location_city, label: "My Cities"),
                const SizedBox(width: 40), 
                _buildTabItem(index: 1, icon: Icons.receipt_long, label: "Subscription"),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem({required int index, required IconData icon, required String label}) {
    bool isSelected = _currentTab == index;
    Color itemColor = const Color(0xFF0D2C54); 
    
    return InkWell(
      onTap: () => setState(() => _currentTab = index),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: itemColor, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: itemColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
                fontFamily: 'serif',
              ),
            )
          ],
        ),
      ),
    );
  }
}