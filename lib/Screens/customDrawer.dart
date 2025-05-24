import 'dart:io';
import 'package:flutter/material.dart';

class CustomDrawer extends StatefulWidget {
  final String currentUserEmail;
  final String? profileImagePath;
  final String userName;
  final String userHandicap;
  final VoidCallback onLogout;

  const CustomDrawer({
    super.key,
    required this.currentUserEmail,
    required this.profileImagePath,
    required this.userName,
    required this.userHandicap,
    required this.onLogout,
  });

  @override
  _CustomDrawerState createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  String selectedLanguage = "EN";
  bool pushNotificationsEnabled = true;
  bool darkModeEnabled = true;

  void _showEnlargedImage(BuildContext context, ImageProvider image) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            height: 300,
            width: 300,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              image: DecorationImage(
                image: image,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsOptions() {
    return Column(
      children: [
        // Language Dropdown with flag emojis
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          child: DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: "Language",
              labelStyle: TextStyle(color: Colors.white70, fontSize: 14),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white70),
              ),
            ),
            value: selectedLanguage,
            items: const [
              DropdownMenuItem(
                value: "EN",
                child: Row(
                  children: [
                    Text("🇺🇸", style: TextStyle(fontSize: 24)),
                    SizedBox(width: 8),
                    Text("English", style: TextStyle(color: Colors.white, fontSize: 14)),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: "TH",
                child: Row(
                  children: [
                    Text("🇹🇭", style: TextStyle(fontSize: 24)),
                    SizedBox(width: 8),
                    Text("Thai", style: TextStyle(color: Colors.white, fontSize: 14)),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: "Burmese",
                child: Row(
                  children: [
                    Text("🇲🇲", style: TextStyle(fontSize: 24)),
                    SizedBox(width: 8),
                    Text("Burmese", style: TextStyle(color: Colors.white, fontSize: 14)),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: "Chinese",
                child: Row(
                  children: [
                    Text("🇨🇳", style: TextStyle(fontSize: 24)),
                    SizedBox(width: 8),
                    Text("Chinese", style: TextStyle(color: Colors.white, fontSize: 14)),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: "Japanese",
                child: Row(
                  children: [
                    Text("🇯🇵", style: TextStyle(fontSize: 24)),
                    SizedBox(width: 8),
                    Text("Japanese", style: TextStyle(color: Colors.white, fontSize: 14)),
                  ],
                ),
              ),
            ],
            onChanged: (value) {
              setState(() {
                selectedLanguage = value!;
              });
            },
            dropdownColor: Colors.grey[800],
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
        // Push Notification Toggle
        SwitchListTile(
          title: const Text("Push Notifications", style: TextStyle(color: Colors.white70, fontSize: 14)),
          value: pushNotificationsEnabled,
          onChanged: (bool value) {
            setState(() {
              pushNotificationsEnabled = value;
            });
          },
          activeColor: Colors.amber,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        // Dark Mode Toggle
        SwitchListTile(
          title: const Text("Dark Mode", style: TextStyle(color: Colors.white70, fontSize: 14)),
          value: darkModeEnabled,
          onChanged: (bool value) {
            setState(() {
              darkModeEnabled = value;
            });
          },
          activeColor: Colors.amber,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        // Privacy Policy Option
        ListTile(
          leading: const Icon(Icons.lock_outline, color: Colors.white70, size: 20),
          title: const Text("Privacy Policy", style: TextStyle(color: Colors.white70, fontSize: 14)),
          onTap: () {
          },
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        ListTile(
          leading: const Icon(Icons.help_outline, color: Colors.white70, size: 20),
          title: const Text("Help & Support", style: TextStyle(color: Colors.white70, fontSize: 14)),
          onTap: () {
          },
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider profileImage;
    if (widget.profileImagePath != null && widget.profileImagePath!.isNotEmpty) {
      profileImage = FileImage(File(widget.profileImagePath!));
    } else {
      profileImage = const AssetImage('assets/img/profile.png');
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 250),
      child: Drawer(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
        ),
        child: Container(
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
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => _showEnlargedImage(context, profileImage),
                      child: CircleAvatar(
                        radius: 35,
                        backgroundImage: profileImage,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      widget.userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Handicap: ${widget.userHandicap}",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              ExpansionTile(
                leading: const Icon(Icons.settings, color: Colors.white, size: 22),
                title: const Text('Settings', style: TextStyle(color: Colors.white, fontSize: 16)),
                backgroundColor: Colors.transparent,
                collapsedBackgroundColor: Colors.transparent,
                children: [
                  _buildSettingsOptions(),
                ],
              ),
              ListTile(
                leading: const Icon(Icons.favorite, color: Colors.white, size: 22),
                title: const Text('Liked Courses', style: TextStyle(color: Colors.white, fontSize: 16)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/likedCourses');
                },
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.white, size: 22),
                title: const Text('Logout', style: TextStyle(color: Colors.white, fontSize: 16)),
                onTap: () {
                  Navigator.pop(context);
                  widget.onLogout();
                },
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
