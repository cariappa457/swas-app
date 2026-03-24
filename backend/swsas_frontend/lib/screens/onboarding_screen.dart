import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/environment.dart';
import 'main_shell.dart';
import '../widgets/wave_background.dart';
import '../widgets/custom_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        final baseUrl = Environment.apiBaseUrl;
        final url = Uri.parse('$baseUrl/api/register');
        final payload = {
          "firebase_uid": "dummy_firebase_uid_${DateTime.now().millisecondsSinceEpoch}",
          "email": _emailController.text,
          "phone": _phoneController.text,
          "name": _nameController.text,
          "age": 25,
          "auto_distress_enabled": true,
          "mic_access_enabled": false,
          "sensor_monitoring_enabled": true
        };

        final response = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(payload),
        );

        if (response.statusCode == 201 || response.statusCode == 400) {
          // 201 Created or 400 if already exists
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MainShell()),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Failed to register: ${response.statusCode} - ${response.body}")),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e")),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFC8BA2), // Soft pink matching image
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: WavePainter(waveColor: const Color(0xFFFA648C)), // darker pink wave
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 100),
                    const Text(
                      "Register",
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 48),
                    _buildTextField(_nameController, "Full Name"),
                    const SizedBox(height: 16),
                    _buildTextField(_emailController, "Email Address"),
                    const SizedBox(height: 16),
                    _buildTextField(_phoneController, "Phone Number"),
                    const SizedBox(height: 16),
                    _buildTextField(_passwordController, "Password", isPassword: true),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        _buildSocialBtn(Icons.g_mobiledata, fontSize: 30),
                        const SizedBox(width: 16),
                        _buildSocialBtn(Icons.facebook),
                        const SizedBox(width: 16),
                        _buildSocialBtn(Icons.apple),
                      ],
                    ),
                    const SizedBox(height: 48),
                    CustomButton(
                      text: "Register",
                      onPressed: _isLoading ? null : _submit,
                      isLoading: _isLoading,
                      buttonVariant: CustomButtonVariant.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {bool isPassword = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(hint, style: const TextStyle(color: Colors.white, fontSize: 12)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white, width: 1.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white70, width: 1.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white, width: 1.5),
            ),
            filled: false,
          ),
          validator: (val) => val!.isEmpty ? "Enter $hint" : null,
        ),
      ],
    );
  }

  Widget _buildSocialBtn(IconData icon, {double? fontSize}) {
    return Container(
      width: 45,
      height: 35,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Icon(icon, color: const Color(0xFFFA648C), size: fontSize ?? 20),
      ),
    );
  }
}
