import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../partner/partner_main_wrapper.dart';

class PartnerSignUpPage extends StatefulWidget {
  const PartnerSignUpPage({super.key});
  @override
  State<PartnerSignUpPage> createState() => _PartnerSignUpPageState();
}

class _PartnerSignUpPageState extends State<PartnerSignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _domainController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _passwordController = TextEditingController();
  bool isLoading = false;

  void _saveDataAndSignUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isLoading = true);
      try {
        final company = _companyNameController.text.trim();

        // (κρατάμε το ίδιο behavior στη βάση, όπως έχεις ήδη)
        await FirebaseFirestore.instance.collection('partners').doc(company).set({
          'companyName': company,
          'domain': _domainController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'location': _locationController.text.trim(),
          'password': _passwordController.text.trim(),
          'role': 'partner',
        });

        final prefs = await SharedPreferences.getInstance();

       
        await prefs.setString('current_partner', company);

       
        await prefs.remove('current_user');

        await prefs.setBool('isLoggedIn', true);
        await prefs.setBool('isPartner', true);

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const PartnerMainWrapper()),
            (r) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("Error: $e")));
        }
      } finally {
        if (mounted) setState(() => isLoading = false);
      }
    }
  }

  Widget _buildTextField(String hint, TextEditingController controller,
      {bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        validator: (val) => (val == null || val.isEmpty) ? 'Required' : null,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white70),
          filled: true,
          fillColor: const Color(0xFF6C829F),
          suffixIcon: const Icon(Icons.cancel_outlined, color: Colors.white),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
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
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  SizedBox(
                    height: 80,
                    child: Image.asset('assets/logo.png',
                        errorBuilder: (c, e, s) =>
                            const Icon(Icons.business, size: 60)),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    "Business with\nTraVelMiSSion",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 24,
                        fontFamily: 'serif',
                        color: Color(0xFF0D2C54)),
                  ),
                  const SizedBox(height: 15),
                  const Text("Tell us about your business!",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87)),
                  const SizedBox(height: 20),
                  _buildTextField("Company Name*", _companyNameController),
                  _buildTextField("Business domain*", _domainController),
                  _buildTextField("E-mail*", _emailController),
                  _buildTextField("Phone Number*", _phoneController),
                  _buildTextField("Location*", _locationController),
                  _buildTextField("Password*", _passwordController,
                      isPassword: true),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: 150,
                    height: 45,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3E4C63),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: isLoading ? null : _saveDataAndSignUp,
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Ready",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Back",
                        style: TextStyle(color: Colors.grey)),
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
