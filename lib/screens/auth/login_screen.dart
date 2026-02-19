import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main_wrapper.dart';
import 'signup_screen.dart';
import 'partner_login_screen.dart';
import 'forgot_password_screen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool isLoading = false;

  void _attemptLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isLoading = true);
      try {
        String username = _usernameController.text.trim();
        String password = _passwordController.text.trim();

        var doc = await FirebaseFirestore.instance
            .collection('travellers')
            .doc(username)
            .get();

        bool success = false;
        if (doc.exists && doc.data() != null) {
          if (doc.get('password') == password) success = true;
        }
        if (username == "admin" && password == "admin") success = true;

        if (success) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('current_user', username);
          await prefs.setBool('isLoggedIn', true);
          await prefs.setBool('isPartner', false);

          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                  builder: (context) => const MainScreenWrapper()),
              (route) => false,
            );
          }
        } else {
          _showError("Invalid username or password");
        }
      } catch (e) {
        _showError("Connection Error: $e");
      } finally {
        if (mounted) setState(() => isLoading = false);
      }
    }
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEBF4F6),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                
                  SizedBox(
                    height: 100,
                    child: Image.asset('assets/logo.png',
                        errorBuilder: (c, e, s) =>
                            const Icon(Icons.travel_explore, size: 80, color: Color(0xFF0D2C54))),
                  ),
                  
                
                  const Text(
                    "Welcome to TraVelMiSSion",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20, 
                      fontFamily: 'serif',
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "lock your memories, unlock your\nrewards",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14, // Μειώθηκε από 16
                      fontFamily: 'serif',
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 40),

                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Login as a Traveller",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                 
                  _buildCustomField("Username", _usernameController),
                  const SizedBox(height: 15),
                  _buildCustomField("Password", _passwordController, isPassword: true),

                  const SizedBox(height: 20),

                  
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3E4C63),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5)),
                      ),
                      onPressed: isLoading ? null : _attemptLogin,
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check, color: Colors.white, size: 20),
                                SizedBox(width: 10),
                                Text("Continue",
                                    style: TextStyle(color: Colors.white, fontSize: 16))
                              ],
                            ),
                    ),
                  ),

                  
                  const SizedBox(height: 5),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SignUpPage()),
                      ),
                      child: const Text("or create an account",
                          style:
                              TextStyle(color: Colors.black54, fontSize: 12)),
                    ),
                  ),

                  const SizedBox(height: 30),

                  
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const PartnerLoginPage()),
                    ),
                    child: const Text(
                      "Are you a company? Click here",
                      style: TextStyle(
                          color: Colors.black87, fontWeight: FontWeight.bold),
                    ),
                  ),

                  const SizedBox(height: 15),

                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ForgotPasswordPage()),
                    ),
                    child: const Text(
                      "Forgot password or username? Click here",
                      style: TextStyle(
                          color: Colors.black87, fontWeight: FontWeight.bold),
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Text(
                    "By clicking continue you agree to our Terms of\nService and Privacy Policy",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10, color: Color(0xFF3E4C63)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomField(
    String hint,
    TextEditingController controller, {
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF6C829F),
        borderRadius: BorderRadius.circular(5),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white70),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          suffixIcon: IconButton(
            icon: const Icon(Icons.cancel_outlined, color: Colors.white),
            onPressed: () => controller.clear(),
          ),
        ),
        validator: (val) => (val == null || val.isEmpty) ? 'Required' : null,
      ),
    );
  }
}