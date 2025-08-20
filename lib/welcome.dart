import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'Room/bedroom.dart';
import 'Room/kitchen.dart';
import 'Room/living_room.dart';
import 'Room/study_room.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'static_page.dart';
import 'routine_page.dart';
import 'setting_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'meter_data_points.dart';
// 📍 LOCATION HELPER
class Location {
  double? latitude;
  double? longitude;

  Future<void> getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      latitude = position.latitude;
      longitude = position.longitude;
    } catch (e) {
      print("Location Error: $e");
    }
  }
}

// 🌐 NETWORK HELPER FOR WEATHER API
class NetworkHelper {
  final String url;
  NetworkHelper(this.url);

  Future getData() async {
    try {
      final uri = Uri.parse(url);
      http.Response response = await http.get(uri);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Failed to load data: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Network error: $e');
      return null;
    }
  }
}

// 🏠 MAIN WELCOME SCREEN
class WelcomeScreen extends StatefulWidget {
  final String userEmail;

  const WelcomeScreen({Key? key, required this.userEmail}) : super(key: key);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  String userName = '';
  File? _profileImage;
  bool mqttConnected = false;
  Map<String, dynamic>? weatherData;
  late MqttServerClient mqttClient;
  int _selectedIndex = 0;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;




  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }


  Future<void> _handleConnectivityChange(ConnectivityResult result) async {
    bool hasInternet = false;

    try {
      final lookup = await InternetAddress.lookup('google.com');
      if (lookup.isNotEmpty && lookup[0].rawAddress.isNotEmpty) {
        hasInternet = true;
      }
    } on SocketException catch (_) {
      hasInternet = false;
    }

    if (!hasInternet) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.wifi_off, color: Colors.white),
              SizedBox(width: 8),
              Text('You are currently offline'),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.wifi, color: Colors.white),
              SizedBox(width: 8),
              Text('Your internet connection has been restored'),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }


  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadProfileImageFromPrefs();
    requestLocationPermission();
    _loadWeatherData();
    _initmqtt();

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((resultList) {
      final result = resultList.isNotEmpty ? resultList.first : ConnectivityResult.none;
      _handleConnectivityChange(result);
    });

  }

  Future<void> _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();

    bool hasInternet = false;

    // Try accessing Google to verify internet access
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        hasInternet = true;
      }
    } on SocketException catch (_) {
      hasInternet = false;
    }

    if (connectivityResult == ConnectivityResult.none || !hasInternet) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.wifi_off, color: Colors.white),
              SizedBox(width: 8),
              Text('You are currently offline'),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.wifi, color: Colors.white),
              SizedBox(width: 8),
              Text('Your internet connection has been restored'),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // NotificationService
  //     .showInstantNotification(
  // "Notification",
  // "Invoice Downloaded");

  Future<void> _initmqtt() async {
    final server = 'broker.sensorsatwork.com';
    final port = 1883;
    final username = 'appuser';
    final password = 'Pulsar-123#';

    mqttClient = MqttServerClient(server, '');
    mqttClient.logging(on: false);
    mqttClient.port = port;
    mqttClient.secure = false;
    mqttClient.setProtocolV311();
    mqttClient.keepAlivePeriod = 20;
    mqttClient.autoReconnect = true;

    try {
      await mqttClient.connect(username, password);
      if (!mounted) return; // new change
      if (mqttClient.connectionStatus?.state == MqttConnectionState.connected) {
        setState(() {
          mqttConnected = true;
        });
        print('✅ Connected to MQTT broker');
      } else {
        setState(() {
          mqttConnected = false;
        });
        print('❌ MQTT connection failed: ${mqttClient.connectionStatus}');
      }
    } catch (e) {
      print('❌ MQTT error: $e');
      mqttClient.disconnect();
      setState(() {
        mqttConnected = false;
      });
    }

    void publishMessage(String topic, String message) {
      final builder = MqttClientPayloadBuilder();
      builder.addString(message);
      mqttClient.publishMessage(
        topic,
        MqttQos.atMostOnce,
        builder.payload!,
        retain: true,
      );
      print("📤 Published to $topic: $message");
    }
  }

  Future<void> _loadUserName() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      debugPrint("❌ No user is currently signed in.");
      return;
    }

    final uid = user.uid;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('uid', uid);

    // 🖨️ Print UID and full user object
    debugPrint("✅ UID: $uid");
    debugPrint("👤 Current User: ${user.toString()}");

    if (!mounted) return;

    setState(() {
      userName = user.displayName ?? 'User';
    });
  }


  Future<void> _loadProfileImageFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('profile_image_path');
    if (path != null && File(path).existsSync()) {
      setState(() {
        _profileImage = File(path);
      });
    }
  }

  // function to check if user has granted location permissions are
  Future<bool> requestLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  Future<void> _loadWeatherData() async {
    Location location = Location();
    await location.getCurrentLocation();

    String apiKey = '069e45f031fda17952b5e59ed9226719'; // Replace with your key
    String url =
        'https://api.openweathermap.org/data/2.5/weather?lat=${location.latitude}&lon=${location.longitude}&appid=$apiKey&units=metric';

    print('Latitude: ${location.latitude}, Longitude: ${location.longitude}');

    NetworkHelper helper = NetworkHelper(url);
    var data = await helper.getData();

    if (data != null &&
        mounted // new Change
        ) {
      setState(() {
        weatherData = data;
      });
    }
  }

  Future<void> _openProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                ProfileScreen(userName: userName, userEmail: widget.userEmail),
      ),
    );
    _loadUserName(); // Reload in case user updated name
  }

  void _onItemTapped(int index) async {
    if (index == _selectedIndex) return;

    switch (index) {
      case 0:
        // Already on home, just set index
        setState(() {
          _selectedIndex = 0;
        });
        break;

      case 1:
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => StaticsPage(mqttClient: mqttClient)),
        );
        setState(() {
          _selectedIndex = 0; // reset to Home after returning
        });
        break;

      case 2:
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RoutinePage(mqttClient: mqttClient),
          ),
        );
        setState(() {
          _selectedIndex = 0; // reset to Home after returning
        });
        break;

      case 3:
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SettingPage(mqttClient: mqttClient),
          ),
        );
        setState(() {
          _selectedIndex = 0; // reset to Home after returning
        });
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 20, 20, 39),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 11, 11, 22),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, $userName',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Welcome to your smart home',
              style: TextStyle(
                fontSize: 12,
                color: Color.fromARGB(179, 234, 232, 232),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: InkWell(
              borderRadius: BorderRadius.circular(50),
              onTap: _openProfile,
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white,
                backgroundImage:
                    _profileImage != null ? FileImage(_profileImage!) : null,
                child:
                    _profileImage == null
                        ? Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : '',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.black87,
                          ),
                        )
                        : null,
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.shade800, height: 1.0),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // _checkConnectivity();
          await _loadUserName();
          await _loadWeatherData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // 🔴 Show Disconnected Banner
              if (!mqttConnected)
                Container(
                  color: Colors.red.shade700,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "MQTT Disconnected",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        onPressed: () async {
                          await _initmqtt(); // manual reconnect
                        },
                      ),
                    ],
                  ),
                ),


              const SizedBox(height: 16),
              weatherData != null
                  ? WeatherWidget(weatherData: weatherData!)
                  : const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                child: Text(
                  "Your Rooms",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1,
                  children: [
                    RoomCard(
                      title: "Living Room",
                      devices: LivingRoomPage.deviceNames.length,
                      image: 'assets/living_room.jpg',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => LivingRoomPage(
                                  mqttClient: mqttClient,
                                ), // Your target page
                          ),
                        );
                      },
                    ),
                    RoomCard(
                      title: "Bedroom",
                      devices: BedroomPage.deviceNames.length,
                      image: 'assets/bedroom.jpg',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    BedroomPage(mqttClient: mqttClient),
                          ),
                        );
                      },
                    ),
                    RoomCard(
                      title: "Study Room",
                      devices: StudyRoomPage.deviceNames.length,
                      image: 'assets/study_room.jpg',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    StudyRoomPage(mqttClient: mqttClient),
                          ),
                        );
                      },
                    ),
                    RoomCard(
                      title: "Kitchen",
                      devices: KitchenPage.deviceNames.length,
                      image: 'assets/kitchen.jpg',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    KitchenPage(mqttClient: mqttClient),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Color(0xFFFF9900),
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Statics', // consider renaming to "Statistics"
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule),
            label: 'Routines',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Setting'),
        ],
      ),
    );
  }
}

class WeatherWidget extends StatelessWidget {
  final Map<String, dynamic> weatherData;
  const WeatherWidget({super.key, required this.weatherData});

  @override
  Widget build(BuildContext context) {
    final String condition = weatherData['weather'][0]['main'] ?? 'Condition';
    final String location = weatherData['name'] ?? 'Unknown';
    final double temp = (weatherData['main']['temp'] ?? 0).toDouble();
    final double feelsLike =
        (weatherData['main']['feels_like'] ?? 0).toDouble();
    final int humidity = (weatherData['main']['humidity'] ?? 0).toInt();
    final double wind = (weatherData['wind']['speed'] ?? 0).toDouble();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF202040),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.cloud, color: Colors.white, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      condition,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      location,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${temp.toStringAsFixed(0)}°',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Bottom metrics
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _WeatherStat(
                label: "Feels like",
                value: "${feelsLike.toInt()}°C",
              ),
              _WeatherStat(label: "Humidity", value: "$humidity%"),
              _WeatherStat(label: "Wind", value: "${wind.toInt()} km/h"),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeatherStat extends StatelessWidget {
  final String label;
  final String value;

  const _WeatherStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 12),
        ),
      ],
    );
  }
}

class RoomCard extends StatelessWidget {
  final String title;
  final int devices;
  final String image;
  final VoidCallback onTap;

  const RoomCard({
    Key? key,
    required this.title,
    required this.devices,
    required this.image,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF202040),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                image,
                width: 70,
                height: 70,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "${devices.toString().padLeft(2, '0')} Devices",
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
