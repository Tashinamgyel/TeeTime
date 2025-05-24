import 'package:flutter/material.dart';
import 'package:tee_time/Helper/databaseHelperPage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:tee_time/user_state.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});
  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _handicapController = TextEditingController();
  String _selectedGender = "Male";
  File? _image;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile();
      _loadProfileImage();
    });
  }

  void _loadProfile() async {
    final email = Provider.of<UserState>(context, listen: false).email;
    try {
      final user = await DatabaseHelper().getUser(email);
      if (user != null) {
        setState(() {
          _nameController.text = user["name"] ?? "";
          _emailController.text = user["email"] ?? "";
          _phoneController.text = user["phone"] ?? "";
          _dobController.text = user["dob"] ?? "";
          _handicapController.text = user["handicap"] ?? "";
          _selectedGender = user["gender"] ?? "Male";
        });
      } else {
        debugPrint("User not found for email: $email");
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
    }
  }

  void _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final email = Provider.of<UserState>(context, listen: false).email;
    final imagePath = prefs.getString("profileImage_$email");
    if (imagePath != null) {
      setState(() {
        _image = File(imagePath);
      });
    }
  }

  Future<void> _saveProfileImage(String path) async {
    final prefs = await SharedPreferences.getInstance();
    final email = Provider.of<UserState>(context, listen: false).email;
    await prefs.setString("profileImage_$email", path);
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await ImagePicker().pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });
        _saveProfileImage(pickedFile.path);
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error selecting image.")),
      );
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(15),
          height: 150,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.black),
                title: const Text("Take Photo"),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.image, color: Colors.black),
                title: const Text("Choose from Gallery"),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _previewImage() {
    if (_image != null) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: InteractiveViewer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.file(_image!),
              ),
            ),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No profile image to preview.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = Provider.of<UserState>(context).email;
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Edit Profile",
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Anton',
            fontWeight: FontWeight.normal,
          ),
        ),
        backgroundColor: const Color.fromRGBO(37, 42, 46, 1),
        elevation: 0,
      ),
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromRGBO(37, 42, 46, 1),
                Color.fromRGBO(50, 60, 68, 1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _previewImage,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white,
                    backgroundImage: _image != null
                        ? FileImage(_image!)
                        : const AssetImage('assets/img/profile_placeholder.png')
                    as ImageProvider,
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _showImagePickerOptions,
                  icon: const Icon(Icons.edit, color: Colors.white),
                  label: const Text("Edit Picture", style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[700],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Container(
                  width: screenWidth * 0.9,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildLabeledInput("Name", _nameController, "Enter your name"),
                      const SizedBox(height: 12),
                      _buildLabeledInput("Email", _emailController, "Enter your email"),
                      const SizedBox(height: 12),
                      _buildLabeledInput("Phone Number", _phoneController, "Enter your phone number"),
                      const SizedBox(height: 12),
                      _buildLabeledDropdown("Gender", screenWidth * 0.9 - 32),
                      const SizedBox(height: 12),
                      _buildLabeledInput("Date of Birth", _dobController, "DD/MM/YYYY"),
                      const SizedBox(height: 12),
                      _buildLabeledInput("Handicap", _handicapController, "Enter your handicap"),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: screenWidth * 0.85,
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        final user = await DatabaseHelper().getUser(userEmail);
                        if (user != null) {
                          await DatabaseHelper().updateUser(user['id'], {
                            "name": _nameController.text.trim(),
                            "email": _emailController.text.trim().toLowerCase(),
                            "phone": _phoneController.text.trim(),
                            "dob": _dobController.text.trim(),
                            "handicap": _handicapController.text.trim(),
                            "gender": _selectedGender,
                          });
                          if (_emailController.text.trim().toLowerCase() != userEmail) {
                            Provider.of<UserState>(context, listen: false)
                                .setEmail(_emailController.text.trim().toLowerCase());
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Profile updated successfully")),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Error updating profile")),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(250, 21, 35, 37),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    ),
                    child: const Text("Confirm", style: TextStyle(color: Colors.white, fontSize: 18)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabeledInput(String label, TextEditingController controller, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 5),
        Container(
          decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: InputBorder.none,
              hintText: hint,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabeledDropdown(String label, double width) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 5),
        Container(
          width: width,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedGender,
              isExpanded: true,
              items: ["Male", "Female", "Other"].map((gender) {
                return DropdownMenuItem<String>(
                  value: gender,
                  child: Text(gender),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedGender = value ?? "Male"),
            ),
          ),
        ),
      ],
    );
  }
}
