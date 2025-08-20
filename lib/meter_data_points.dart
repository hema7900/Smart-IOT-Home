import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubscribedDataPage extends StatefulWidget {
  final MqttServerClient mqttClient;

  const SubscribedDataPage({Key? key, required this.mqttClient})
    : super(key: key);

  @override
  State<SubscribedDataPage> createState() => _SubscribedDataPageState();
}

class _SubscribedDataPageState extends State<SubscribedDataPage> {
  String _latestMessage = "Waiting for data...";
  StreamSubscription? _mqttSubscription;

  @override
  void initState() {
    super.initState();
    _loadTopicAndSubscribe();
  }

  @override
  void dispose() {
    _mqttSubscription?.cancel();
    _unsubscribeTopic();
    super.dispose();
  }

  Future<void> _unsubscribeTopic() async {
    final prefs = await SharedPreferences.getInstance();
    final meterId = prefs.getString('meter_id');
    if (meterId != null && meterId.isNotEmpty) {
      final topic = '/topic/ems/$meterId';
      widget.mqttClient.unsubscribe(topic);
      print('Unsubscribed from $topic');
    }
  }

  Future<void> _loadTopicAndSubscribe() async {
    final prefs = await SharedPreferences.getInstance();
    _latestMessage = prefs.getString('last_message') ?? "Waiting for data...";
    final meterId = prefs.getString('meter_id');

    if (meterId == null || meterId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _latestMessage = "No meter ID found in preferences.";
      });
      return;
    }

    final topic = '/topic/ems/$meterId';
    widget.mqttClient.subscribe(topic, MqttQos.atMostOnce);
    _mqttSubscription = widget.mqttClient.updates?.listen((
      List<MqttReceivedMessage<MqttMessage>> c,
    ) async {
      final recMessage = c[0].payload as MqttPublishMessage;
      final MSG = MqttPublishPayload.bytesToStringAsString(
        recMessage.payload.message,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_message', MSG);
      if (mounted) {
        setState(() {
          _latestMessage = MSG;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: const Color(0xFF181829),
        title: const Text(
          "Live Meter Data",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        leading: const BackButton(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    "Live Data",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _latestMessage,
                    style: const TextStyle(
                      fontSize: 22,
                      color: Colors.blueGrey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
