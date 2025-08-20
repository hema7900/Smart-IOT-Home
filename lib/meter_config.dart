import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MeterPage extends StatefulWidget {
  const MeterPage({Key? key}) : super(key: key);

  @override
  State<MeterPage> createState() => _MeterPageState();
}

class _MeterPageState extends State<MeterPage> {
  final TextEditingController _deviceIdController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final bool _isLoading = false;

  void _saveDeviceId() async {
    final deviceId = _deviceIdController.text.trim();
    if (deviceId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('meter_id', deviceId);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Device ID "$deviceId" saved successfully',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
    ;

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: const Color(0xFF181829),
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: const Text(
          "Meter Subscription",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Subscribe to a Device",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Please enter your Device ID to save.",
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 30),

                  _buildDeviceIdField(),

                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      // icon: const Icon(Icons.wifi),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        if (_formKey.currentState?.validate() ?? false) {
                          _saveDeviceId();
                        }
                      },
                      label: const Text('Save', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.orange),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDeviceIdField() {
    return TextFormField(
      controller: _deviceIdController,
      validator: (value) {
        if (value == null || value.isEmpty) return 'Please enter Device ID';
        if (value.length < 3) return 'Device ID must be at least 3 characters';
        return null;
      },
      decoration: InputDecoration(
        labelText: "Device ID",
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 18,
          horizontal: 16,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
