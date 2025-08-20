import 'package:flutter/material.dart';
import 'package:flutter_application_1/login.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  final String userName;
  final String userEmail;

  const ProfileScreen({
    Key? key,
    required this.userName,
    required this.userEmail,
  }) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  DateTime? _dateTime;
  bool _valueChanged = false;
  File? _profileImage;
  final picker = ImagePicker();

  Future showOptions() async {
    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => CupertinoActionSheet(
            actions: [
              CupertinoActionSheetAction(
                child: Text('Photo Gallery'),
                onPressed: () {
                  // close the options modal
                  Navigator.of(context).pop();
                  // get image from gallery
                  getImageFromGallery();
                },
              ),
              CupertinoActionSheetAction(
                child: Text('Camera'),
                onPressed: () {
                  // close the options modal
                  Navigator.of(context).pop();
                  // get image from camera
                  getImageFromCamera();
                },
              ),
            ],
          ),
    );
  }

  Future<void> getImageFromGallery() async {
    final result = await picker.pickImage(source: ImageSource.gallery);
    if (result != null) {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/profile.png';
      await FileImage(File(filePath)).evict();
      final savedImage = await File(result.path).copy(filePath);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_image_path', filePath);
      setState(() {
        _profileImage = savedImage;
      });
    } else {
      print('❌ No image selected.');
    }
  }

  Future<void> getImageFromCamera() async {
    final result = await picker.pickImage(source: ImageSource.camera);
    if (result != null) {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/profile.png';
      await FileImage(File(filePath)).evict();
      final savedImage = await File(result.path).copy(filePath);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_image_path', filePath);
      setState(() {
        _profileImage = savedImage;
      });
    } else {
      print('No image captured.');
    }
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
  void initState() {
    super.initState();
    _loadProfileImageFromPrefs();
    final user = FirebaseAuth.instance.currentUser;
    nameController.text = widget.userName;
    emailController.text = widget.userEmail;
  }

  void showTopSnackBar(
    BuildContext context,
    String message, {
    Duration? duration,
    Color color = Colors.grey,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        dismissDirection: DismissDirection.up,
        duration: duration ?? const Duration(seconds: 1),
        backgroundColor: color,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 100,
          left: 10,
          right: 10,
        ),
        behavior: SnackBarBehavior.floating,
        content: Text(
          message,
          style: const TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(color: Colors.white),
        backgroundColor: const Color.fromARGB(255, 11, 11, 22),
        centerTitle: true,
        title: const Text(
          'Profile',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        elevation: 1,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: showOptions,
                      child: CircleAvatar(
                        radius: 45,
                        backgroundColor: Colors.grey[350],
                        backgroundImage:
                            _profileImage != null
                                ? FileImage(_profileImage!)
                                : null,
                        child:
                            _profileImage == null
                                ? const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.grey,
                                )
                                : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () {
                          // Edit avatar tapped (future implementation)
                        },
                        child: Container(
                          height: 28,
                          width: 28,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            color: Colors.grey,
                          ),
                          child: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              const Text("Name", style: TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  hintText: 'Name',
                  border: OutlineInputBorder(),
                ),
                validator:
                    (val) =>
                        val?.trim().isEmpty == true
                            ? 'Name cannot be empty'
                            : null,
                onChanged: (_) {
                  setState(() {
                    _valueChanged = true;
                  });
                },
              ),

              const SizedBox(height: 16),
              const Text("Email", style: TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              TextFormField(
                controller: emailController,
                enabled: false,
                decoration: const InputDecoration(
                  hintText: 'Email',
                  border: OutlineInputBorder(),
                  disabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              const Text("Date Of Birth", style: TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _dateTime ?? DateTime(2000),
                    firstDate: DateTime(1900),
                    lastDate: now,
                  );
                  if (picked != null && picked != _dateTime) {
                    setState(() {
                      _dateTime = picked;
                      _valueChanged = true;
                    });
                  }
                },
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: InputDecoration(
                      hintText:
                          _dateTime != null
                              ? DateFormat('dd/mm/yyyy').format(_dateTime!)
                              : 'dd/mm/yyyy',
                      border: const OutlineInputBorder(),
                      suffixIcon: const Icon(Icons.calendar_today),
                    ),
                    validator:
                        (_) =>
                            _dateTime == null
                                ? 'Please select Date of Birth'
                                : null,
                  ),
                ),
              ),

              const SizedBox(height: 16),
              const Text("Location", style: TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              TextFormField(
                controller: addressController,
                decoration: const InputDecoration(
                  hintText: 'Address',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) {
                  setState(() {
                    _valueChanged = true;
                  });
                },
              ),

              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed:
                      _valueChanged
                          ? () async {
                            if (_formKey.currentState?.validate() ?? false) {
                              final newName = nameController.text.trim();
                              try {
                                User? user = FirebaseAuth.instance.currentUser;
                                if (user != null) {
                                  await user.updateDisplayName(newName);
                                  await user.reload(); // Refresh Firebase user
                                  showTopSnackBar(
                                    context,
                                    "Profile updated successfully",
                                    color: Colors.green,
                                  );
                                  FocusScope.of(context).unfocus();
                                }
                              } catch (e) {
                                showTopSnackBar(
                                  context,
                                  "Failed to update profile: $e",
                                  color: Colors.red,
                                );
                              }

                              setState(() {
                                _valueChanged = false;
                              });
                            }
                          }
                          : null,
                  child: const Text("Update Profile"),
                ),
              ),

              // const SizedBox(height: 32),
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    final shouldLogout = await showDialog<bool>(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: const Text("Confirm Logout"),
                            content: const Text(
                              "Are you sure you want to logout?",
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text("Cancel"),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text("Logout"),
                              ),
                            ],
                          ),
                    );

                    if (shouldLogout == true) {
                      await FirebaseAuth.instance.signOut();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LoginScreen()),
                      );
                    }
                  },
                  child: const Text("Logout"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
