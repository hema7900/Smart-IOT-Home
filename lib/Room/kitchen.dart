import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KitchenPage extends StatefulWidget {
  final MqttServerClient mqttClient;
  const KitchenPage({Key? key, required this.mqttClient}) : super(key: key);

  static const List<String> deviceNames = [
    'Exhaust Fan',
    'Ceiling Light',
    'Cabinet Lights',
    'Water Purifier',
  ];

  @override
  _KitchenPageState createState() => _KitchenPageState();
}

class _KitchenPageState extends State<KitchenPage> {
  String uid = '';
  final Map<String, bool> deviceStates = {};
  final Map<String, String> deviceImages = {
    'Exhaust Fan': 'assets/exhaust.jpg',
    'Ceiling Light': 'assets/ceiling.jpg',
    'Cabinet Lights': 'assets/cabinet.jpg',
    'Water Purifier': 'assets/purifier.jpg',
  };

  Future<void> _saveDeviceState(String device, bool state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('kitchen_$device', state);
  }

  Future<void> _loadDeviceStates() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      for (var device in KitchenPage.deviceNames) {
        deviceStates[device] = prefs.getBool('kitchen_$device') ?? false;
      }
    });
  }

  Future<void> _loadUserName() async {
    User? user = FirebaseAuth.instance.currentUser;
    uid = user?.uid ?? '';
    print("Loaded userName: $uid"); // 👈 Print statement added
  }

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadDeviceStates(); // 👈 Load saved states before subscribing
    _subscribeToDeviceTopics();
    // print('Initiaize State');
    widget.mqttClient.updates?.listen(_handleMqttMessage);
  }

  void _subscribeToDeviceTopics() {
    for (var device in KitchenPage.deviceNames) {
      final topic = 'users/$uid/room/Kitchen/$device';
      widget.mqttClient.subscribe(topic, MqttQos.atMostOnce);
    }
    // print('topic subscribed');
  }

  void _handleMqttMessage(List<MqttReceivedMessage<MqttMessage>> event) {
    final recMsg = event[0].payload as MqttPublishMessage;
    final Kitchen = MqttPublishPayload.bytesToStringAsString(
      recMsg.payload.message,
    );
    final topic = event[0].topic;
    if (!topic.startsWith('users/$uid/room/Kitchen/')) return; // ✅ Ignore other rooms
    final deviceName = topic.split('/').last;

    if (KitchenPage.deviceNames.contains(deviceName)) {
      final isOn = Kitchen == '1';
      _saveDeviceState(deviceName, isOn); // 👈 Save state
      setState(() {
        deviceStates[deviceName] = isOn;
      });
      // print("Received update for $deviceName: $Kitchen");
    }
  }

  void _publishDeviceState(String device, bool isOn) {
    final message = isOn ? '1' : '0';
    final topic = 'users/$uid/room/Kitchen/$device'; // Example topic
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);

    try {
      widget.mqttClient.publishMessage(
        topic,
        MqttQos.atMostOnce,
        builder.payload!,
        retain: true,
      );
      print('Published to $topic: $message');
    } catch (e) {
      print('Error publishing MQTT message: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 20, 20, 39),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 11, 11, 22),
        title: const Text(
          "Kitchen",
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: BackButton(color: Colors.white),
        centerTitle: true,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.shade800, height: 1.0),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.9,
          children:
              deviceStates.keys.map((device) {
                return _buildDeviceTile(device);
              }).toList(),
        ),
      ),
    );
  }

  Widget _buildDeviceTile(String deviceName) {
    bool isOn = deviceStates[deviceName]!;
    // double imageSize = (deviceName == 'Fan' || deviceName == 'Bulb') ? 70 : 50;
    // print('UI Initialize');

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF202040),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset(
            deviceImages[deviceName]!,
            fit: BoxFit.contain,
            width: 80,
            height: 80,
          ),
          Text(
            deviceName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isOn ? "On" : "Off",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              Switch(
                value: isOn,
                onChanged: (val) {
                  setState(() {
                    deviceStates[deviceName] = val;
                  });
                  _publishDeviceState(deviceName, val); // Publish message here
                },
                activeColor: Colors.blue,
                inactiveThumbColor: Colors.redAccent,
                inactiveTrackColor: Colors.red.withOpacity(0.4),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
