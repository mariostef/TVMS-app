import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});
  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newUsernameController = TextEditingController();
  final _newPasswordController = TextEditingController();

  String? _generatedCode;
  bool _isCodeVerified = false;
  bool _isLoading = false;

  // Θα κρατάμε εδώ το docId (που είναι το username στο SignUp σου)
  String? _foundUserDocId;
  Map<String, dynamic>? _foundUserData;

  Future<bool> _findUserByEmail(String email) async {
    final snap = await FirebaseFirestore.instance
        .collection('travellers')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return false;

    _foundUserDocId = snap.docs.first.id; // doc id = username
    _foundUserData = snap.docs.first.data();
    return true;
  }

  Future<void> _sendRealEmail() async {
    final email = _emailController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid email.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final exists = await _findUserByEmail(email);
      if (!exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: Colors.red, content: Text("❌ This email is not registered.")),
        );
        return;
      }

      final code = (Random().nextInt(9000) + 1000).toString();
      _generatedCode = code;

      // --- EmailJS KEYS ---
      const serviceId = 'service_vbz7ku5';
      const templateId = 'template_8mu82js';
      const userId = '8yHujCor-OlvxwK-A';
      final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'service_id': serviceId,
          'template_id': templateId,
          'user_id': userId,
          'template_params': {
            'to_name': 'Traveller',
            'to_email': email,
            'message': code,
          }
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: Colors.green, content: Text("✅ Code sent! Check your inbox.")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red, content: Text("Failed: ${response.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red, content: Text("Error: $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _verifyCode() {
    if (_codeController.text.trim() == _generatedCode) {
      setState(() => _isCodeVerified = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: Colors.green, content: Text("✅ Code Verified!")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: Colors.red, content: Text("❌ Wrong Code! Try again.")),
      );
    }
  }

  Future<void> _updateData() async {
    if (!_isCodeVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Verify code first!")),
      );
      return;
    }

    final email = _emailController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid email.")),
      );
      return;
    }

    final newUsername = _newUsernameController.text.trim();
    final newPassword = _newPasswordController.text.trim();

    if (newPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a new password.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_foundUserDocId == null) {
        final exists = await _findUserByEmail(email);
        if (!exists) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(backgroundColor: Colors.red, content: Text("❌ This email is not registered.")),
          );
          return;
        }
      }

      final oldDocId = _foundUserDocId!;
      final oldData = _foundUserData ?? {};

      final travellers = FirebaseFirestore.instance.collection('travellers');

      if (newUsername.isEmpty || newUsername == oldDocId) {
        await travellers.doc(oldDocId).update({
          'password': newPassword,
        });

  
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', oldDocId);
        await prefs.setBool('isLoggedIn', false);

      } else {
 
        final newDocId = newUsername;

        final batch = FirebaseFirestore.instance.batch();

        final newDocRef = travellers.doc(newDocId);
        final oldDocRef = travellers.doc(oldDocId);

        final newDocData = <String, dynamic>{
          ...oldData,
          'username': newDocId,
          'email': email,
          'password': newPassword,
          
        };

        batch.set(newDocRef, newDocData);
        batch.delete(oldDocRef);

        await batch.commit();

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', newDocId);
        await prefs.setBool('isLoggedIn', false);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: Colors.green, content: Text("✅ Password updated! Please login again.")),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red, content: Text("Error: $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildTextField(String hint, TextEditingController controller, {bool obscure = false}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFF6C829F),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: BorderSide.none,
        ),
      ),
      style: const TextStyle(color: Colors.white),
    );
  }

  Widget _buildButton(String text, VoidCallback onPress) {
    return SizedBox(
      width: double.infinity,
      height: 45,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3E4C63)),
        onPressed: onPress,
        child: Text(text, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _newUsernameController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEBF4F6),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              children: [
                Image.asset('assets/logo.png', height: 100, fit: BoxFit.contain),
                const SizedBox(height: 20),
                const Text("Forgot password?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),

                _buildTextField("Email*", _emailController),
                const SizedBox(height: 10),
                _isLoading
                    ? const CircularProgressIndicator()
                    : _buildButton("Send Verification Code", _sendRealEmail),

                const SizedBox(height: 20),
                _buildTextField("Enter 4-digit Code", _codeController),
                const SizedBox(height: 10),
                _buildButton("Verify Code", _verifyCode),

                const SizedBox(height: 20),
                Opacity(
                  opacity: _isCodeVerified ? 1.0 : 0.5,
                  child: Column(
                    children: [
                      _buildTextField("New Username (optional)", _newUsernameController),
                      const SizedBox(height: 10),
                      _buildTextField("New Password*", _newPasswordController, obscure: true),
                      const SizedBox(height: 10),
                      _isLoading
                          ? const CircularProgressIndicator()
                          : _buildButton("Update Data", () {
                              _updateData();
                            }),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Back"))
              ],
            ),
          ),
        ),
      ),
    );
  }
}
