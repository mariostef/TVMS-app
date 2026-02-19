import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth/login_screen.dart';
import 'map/map_home_screen.dart';
import 'rewards/rewards_home_screen.dart';
import 'gallery/file_home_screen.dart';

class MainScreenWrapper extends StatefulWidget {
  const MainScreenWrapper({super.key});

  @override
  State<MainScreenWrapper> createState() => _MainScreenWrapperState();
}

class _MainScreenWrapperState extends State<MainScreenWrapper> {
  int _selectedIndex = 1;

  final _rewardsNavKey = GlobalKey<NavigatorState>();
  final _mapNavKey = GlobalKey<NavigatorState>();
  final _fileNavKey = GlobalKey<NavigatorState>();

  
  final GlobalKey<FileHomePageState> _fileHomeKey = GlobalKey<FileHomePageState>();

  GlobalKey<NavigatorState> get _currentNavKey {
    switch (_selectedIndex) {
      case 0:
        return _rewardsNavKey;
      case 1:
        return _mapNavKey;
      case 2:
      default:
        return _fileNavKey;
    }
  }

  Future<bool> _onWillPop() async {
    final nav = _currentNavKey.currentState;
    if (nav != null && nav.canPop()) {
      nav.pop();
      return false;
    }
    return true;
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();


await prefs.remove('isLoggedIn');
await prefs.remove('isPartner');
await prefs.remove('current_user');
await prefs.remove('username');     

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Widget _buildTabNavigator({
    required GlobalKey<NavigatorState> navKey,
    required Widget rootPage,
  }) {
    return Navigator(
      key: navKey,
      onGenerateRoute: (settings) {
        return MaterialPageRoute(builder: (_) => rootPage);
      },
    );
  }

  void _handleTabTap(int index) {
    if (index == _selectedIndex) {
      _currentNavKey.currentState?.popUntil((route) => route.isFirst);

     
      if (index == 2) {
        _fileHomeKey.currentState?.refresh();
      }
      return;
    }

    setState(() => _selectedIndex = index);

    
    if (index == 2) {
      _fileHomeKey.currentState?.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text("TVMS"),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _logout,
            )
          ],
        ),
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            _buildTabNavigator(navKey: _rewardsNavKey, rootPage: const RewardsHomePage()),
            _buildTabNavigator(navKey: _mapNavKey, rootPage: const MapHomePage()),
            _buildTabNavigator(navKey: _fileNavKey, rootPage: FileHomePage(key: _fileHomeKey)), // ✅ εδώ
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _handleTabTap,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.card_giftcard), label: "Rewards"),
            BottomNavigationBarItem(icon: Icon(Icons.map), label: "Map"),
            BottomNavigationBarItem(icon: Icon(Icons.folder), label: "File"),
          ],
        ),
      ),
    );
  }
}
