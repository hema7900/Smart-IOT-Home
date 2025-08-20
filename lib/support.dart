// ignore_for_file: file_names, avoid_print

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class Support extends StatelessWidget {
  const Support({super.key});

  Future<void> _launchUrl(Uri url) async {
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      // Could add a snackbar here for user feedback
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final scaffoldKey = GlobalKey<ScaffoldState>();

    return Scaffold(
      // backgroundColor: const Color.fromARGB(255, 240, 240, 242),
      key: scaffoldKey,
      drawerEnableOpenDragGesture: false,
      appBar: AppBar(
        backgroundColor: const Color(0xFF181829),
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: const Text(
          'Support',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 45),
              Center(
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage("assets/LOGO_B.png"),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 40),
              Text(
                "For any help and support",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                ),
              ),
              SizedBox(height: 20),

              /// Email
              ListTile(
                onTap:
                    () => _launchUrl(Uri.parse("mailto:hemantvats0123@gmail.com")),
                contentPadding: EdgeInsets.only(left: 40),
                leading: const Icon(Icons.email),
                title: Text(
                  "hemantvats0123@gmail.com",
                  style: TextStyle(fontSize: 16),
                ),
              ),

              /// Website
              // ListTile(
              //   onTap:
              //       () => _launchUrl(Uri.parse("https://roadgridindia.com/")),
              //   contentPadding: EdgeInsets.only(left: 40),
              //   leading: const Icon(Icons.language),
              //   title: Text(
              //     "https://roadgridindia.com/",
              //     style: TextStyle(fontSize: 16),
              //   ),
              // ),

              /// Phone
              ListTile(
                onTap: () => _launchUrl(Uri.parse("tel:+91-9149381327")),
                contentPadding: EdgeInsets.only(left: 40),
                leading: const Icon(Icons.phone),
                title: const Text("+91-9149381327"),
              ),

              SizedBox(height: 140),
            ],
          ),
        ),
      ),
    );
  }
}
