import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth/login_screen.dart';
import 'main_wrapper.dart';

class SplashLoader extends StatefulWidget {
  const SplashLoader({super.key});
  @override
  State<SplashLoader> createState() => _SplashLoaderState();
}

class _SplashLoaderState extends State<SplashLoader> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  void _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      if (isLoggedIn) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainScreenWrapper()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFEBF4F6),
      body: Center(child: CircularProgressIndicator()),
    );
  }
}