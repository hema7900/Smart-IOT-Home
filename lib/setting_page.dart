import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile.dart';
import 'support.dart';
import 'change_password.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'meter_config.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'meter_data_points.dart';

class SettingPage extends StatefulWidget {
  final MqttServerClient mqttClient;
  final String userEmail;

  const SettingPage({super.key, required this.mqttClient, this.userEmail = ''});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  User? user;
  String userName = '';
  File? _profileImage;
  late MqttServerClient mqttClient;

  @override
  void initState() {
    super.initState();
    _loadProfileImageFromPrefs();
    user = FirebaseAuth.instance.currentUser;
    mqttClient = widget.mqttClient; 
    setState(() {
      userName = user?.displayName ?? 'User';
    });
  }

  Future<void> _loadProfileImageFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final imagePath = prefs.getString('profile_image_path');
    if (imagePath != null && File(imagePath).existsSync()) {
      setState(() {
        _profileImage = File(imagePath);
      });
    }
  }

  @override
  void dispose() {
    // Cancel any async logic or listeners here if needed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget _buildTile(IconData icon, String title, {VoidCallback? onTap}) {
      return ListTile(
        tileColor: Colors.grey[200],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(icon, color: Colors.black87),
        title: Text(title, style: const TextStyle(color: Colors.black87)),
        onTap: onTap,
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF181829),
      appBar: AppBar(
        backgroundColor: const Color(0xFF181829),
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // 🔹 Dark Header Section (Profile)
          Container(
            color: const Color(0xFF1E1C2A),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white,
                  backgroundImage:
                      _profileImage != null ? FileImage(_profileImage!) : null,
                  child:
                      _profileImage == null
                          ? Text(
                            userName.isNotEmpty
                                ? userName[0].toUpperCase()
                                : '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.black87,
                            ),
                          )
                          : null,
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Hello",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    Text(
                      userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => ProfileScreen(
                              userName: userName,
                              userEmail: widget.userEmail,
                            ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // 🔸 White Expanded Section
          Expanded(
            child: Container(
              color: Colors.white,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    "Preferences",
                    style: TextStyle(color: Colors.black87, fontSize: 16),
                  ),
                  const SizedBox(height: 8),

                  SwitchListTile(
                    value: true,
                    onChanged: (val) {
                      if (mounted) {
                        setState(() {
                          // toggle logic
                        });
                      }
                    },
                    activeColor: Colors.orange,
                    title: const Text(
                      "Notifications",
                      style: TextStyle(color: Colors.black87),
                    ),
                  ),

                  const SizedBox(height: 12),
                  _buildTile(
                    Icons.speed,
                    "Meter",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MeterPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildTile(
                    Icons.speed,
                    "Data Points",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  SubscribedDataPage(mqttClient: mqttClient),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 12),
                  _buildTile(
                    Icons.lock_outline,
                    "Change Password",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ChangePasswordScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildTile(
                    Icons.support_agent,
                    "Support",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const Support(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildTile(
                    Icons.info_outline,
                    "About App",
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: "Smart Home",
                        applicationVersion: "1.0.0",
                        applicationIcon: const Icon(Icons.home, size: 32),
                        children: const [
                          Text(
                            "Manage your home devices with routines and automation.",
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 24),
                  Center(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 225, 22, 8),
                      ),
                      icon: const Icon(
                        Icons.logout,
                        color: Colors.black,
                        size: 24,
                        weight: 700,
                      ),
                      label: const Text(
                        "Logout",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        if (mounted) {
                          Navigator.of(
                            context,
                          ).popUntil((route) => route.isFirst);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
