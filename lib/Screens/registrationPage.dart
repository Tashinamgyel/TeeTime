import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tee_time/Helper/databaseHelperPage.dart';
import 'package:tee_time/Helper/utils.dart';
import 'package:tee_time/user_state.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key, required this.title});
  final String title;
  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _handicapController = TextEditingController();
  final _dobController = TextEditingController();
  String? _gender;
  bool _agree = false;
  bool _isProcessing = false;
  late AnimationController _gradientController;

  @override
  void initState() {
    super.initState();
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage('assets/img/golf_registration.png'), context);
  }

  @override
  void dispose() {
    _gradientController.dispose();
    super.dispose();
  }

  void _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Passwords do not match")));
      return;
    }
    if (!_agree) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Please accept Terms")));
      return;
    }
    setState(() {
      _isProcessing = true;
    });
    final email = normalizeEmail(_emailController.text);
    final password = _passwordController.text.trim();
    final hashedPassword = sha256.convert(utf8.encode(password)).toString();
    final user = {
      "name": _nameController.text.trim(),
      "email": email,
      "password": hashedPassword,
      "phone": _phoneController.text.trim(),
      "handicap": _handicapController.text.trim(),
      "dob": _dobController.text.trim(),
      "gender": _gender,
    };
    try {
      final id = await DatabaseHelper().insertUser(user);
      if (id != null) {
        Provider.of<UserState>(context, listen: false).setEmail(email);
        Navigator.pushNamedAndRemoveUntil(context, '/landing', (route) => false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Registration failed")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("An error occurred during registration")));
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: AnimatedBuilder(
        animation: _gradientController,
        builder: (context, child) {
          final animationValue = _gradientController.value;
          final beginAlignment = AlignmentTween(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).lerp(animationValue);
          final endAlignment = AlignmentTween(
            begin: Alignment.bottomRight,
            end: Alignment.topLeft,
          ).lerp(animationValue);
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: beginAlignment ?? Alignment.topLeft,
                end: endAlignment ?? Alignment.bottomRight,
                colors: const [Color(0xFF252A2E), Color(0xFF323C44)],
              ),
            ),
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      "Tee Time",
                      style: TextStyle(
                        fontSize: 65,
                        fontFamily: 'Anton',
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Image.asset(
                      'assets/img/golf_registration.png',
                      width: screenWidth * 0.5,
                    ),
                    const SizedBox(height: 30),
                    Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      color: Colors.white.withOpacity(0.95),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              _buildTextField(_nameController, "Name"),
                              const SizedBox(height: 10),
                              _buildTextField(_emailController, "Email", isEmail: true),
                              const SizedBox(height: 10),
                              _buildTextField(_phoneController, "Phone"),
                              const SizedBox(height: 10),
                              _buildTextField(_handicapController, "Handicap"),
                              const SizedBox(height: 10),
                              _buildTextField(_dobController, "DOB"),
                              const SizedBox(height: 10),
                              _buildGenderDropdown(),
                              const SizedBox(height: 10),
                              _buildTextField(_passwordController, "Password", isPassword: true),
                              const SizedBox(height: 10),
                              _buildTextField(_confirmPasswordController, "Confirm Password", isPassword: true),
                              const SizedBox(height: 10),
                              _buildAgreementCheckbox(),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: screenWidth * 0.85,
                      child: _isProcessing
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                        onPressed: _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(250, 21, 35, 37),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                        ),
                        child: const Text("Sign Up",
                            style: TextStyle(color: Colors.white, fontSize: 18)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hintText,
      {bool isEmail = false, bool isPassword = false}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: Colors.grey[200],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide.none,
        ),
        hintStyle: TextStyle(color: Colors.grey[600]),
      ),
      keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
      obscureText: isPassword,
      validator: (value) {
        if (value == null || value.isEmpty) return "This field is required";
        if (isEmail &&
            !RegExp(
                r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$")
                .hasMatch(value)) {
          return "Enter a valid email";
        }
        return null;
      },
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      value: _gender,
      hint: const Text("Select Gender"),
      items: ["Male", "Female", "Other"]
          .map((g) => DropdownMenuItem(value: g, child: Text(g)))
          .toList(),
      onChanged: (val) => setState(() => _gender = val),
      validator: (val) => val == null ? "Select gender" : null,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey[200],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide.none,
        ),
        hintStyle: TextStyle(color: Colors.grey[600]),
      ),
    );
  }

  Widget _buildAgreementCheckbox() {
    return Row(
      children: [
        Checkbox(value: _agree, onChanged: (val) => setState(() => _agree = val!)),
        const Expanded(child: Text("I agree to the Terms & Conditions")),
      ],
    );
  }
}
