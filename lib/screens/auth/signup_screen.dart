// signup_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main_wrapper.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});
  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  String selectedAge = "Unknown";
  String selectedSex = "Unknown";
  bool isLoading = false;

  void _saveDataAndSignUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isLoading = true);
      try {
        final username = _usernameController.text.trim();
        final email = _emailController.text.trim();
        final password = _passwordController.text.trim();

        final docRef =
            FirebaseFirestore.instance.collection('travellers').doc(username);

        // ✅ Critical fix: Do NOT overwrite an existing username (atomic).
        await FirebaseFirestore.instance.runTransaction((tx) async {
          final snap = await tx.get(docRef);
          if (snap.exists) {
            throw Exception('USERNAME_TAKEN');
          }
          tx.set(docRef, {
            'username': username,
            'email': email,
            'password': password,
            'age_group': selectedAge,
            'sex': selectedSex,
            'role': 'traveller',
            'unlocked_cities': <String>[],
            'createdAt': FieldValue.serverTimestamp(),
          });
        });

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', username);
        await prefs.setString('current_user', username);
        await prefs.setBool('isLoggedIn', true);
        await prefs.setBool('isPartner', false);

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MainScreenWrapper()),
            (Route<dynamic> route) => false,
          );
        }
      } catch (e) {
        final msg = e.toString().contains('USERNAME_TAKEN')
            ? "This username is already taken. Please choose another one."
            : "Error: $e";
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(msg)));
        }
      } finally {
        if (mounted) setState(() => isLoading = false);
      }
    }
  }

  Widget _buildSelectButton(
      String label, String groupValue, Function(String) onTap) {
    bool isSelected = groupValue == label;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor:
                isSelected ? const Color(0xFF3E4C63) : const Color(0xFF6C829F),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () => onTap(label),
          child: Text(label, style: const TextStyle(fontSize: 12)),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: const Color(0xFF6C829F),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEBF4F6),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  SizedBox(
                    height: 80,
                    child: Image.asset('assets/logo.png',
                        errorBuilder: (c, e, s) =>
                            const Icon(Icons.travel_explore, size: 80)),
                  ),
                  const Text(
                    "Become an official\nTraVelMiSSion explorer now!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'serif',
                        color: Color(0xFF2C3E50)),
                  ),
                  const SizedBox(height: 20),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Select your age group:",
                        style: TextStyle(color: Color(0xFF2C3E50))),
                  ),
                  Row(children: [
                    _buildSelectButton(
                        "<20", selectedAge, (val) => setState(() => selectedAge = val)),
                    _buildSelectButton("20-30", selectedAge,
                        (val) => setState(() => selectedAge = val)),
                    _buildSelectButton(
                        ">30", selectedAge, (val) => setState(() => selectedAge = val)),
                    _buildSelectButton("Unknown", selectedAge,
                        (val) => setState(() => selectedAge = val)),
                  ]),
                  const SizedBox(height: 10),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Select your sex:",
                        style: TextStyle(color: Color(0xFF2C3E50))),
                  ),
                  Row(children: [
                    _buildSelectButton(
                        "Male", selectedSex, (val) => setState(() => selectedSex = val)),
                    _buildSelectButton("Female", selectedSex,
                        (val) => setState(() => selectedSex = val)),
                    _buildSelectButton("Unknown", selectedSex,
                        (val) => setState(() => selectedSex = val)),
                  ]),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _emailController,
                    validator: (val) =>
                        (val!.isEmpty || !val.contains('@')) ? 'Invalid email' : null,
                    decoration: _inputDecoration("email*"),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _usernameController,
                    validator: (val) => val!.isEmpty ? 'Required' : null,
                    decoration: _inputDecoration("Username*"),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    validator: (val) => val!.length < 4 ? 'Min 4 chars' : null,
                    decoration: _inputDecoration("Password*"),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3E4C63),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5)),
                      ),
                      onPressed: isLoading ? null : _saveDataAndSignUp,
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Create Account",
                              style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back,
                          color: Color(0xFF3E4C63)),
                      label: const Text("Back to Login",
                          style: TextStyle(color: Color(0xFF3E4C63))),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
