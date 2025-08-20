import 'dart:isolate';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'notification.dart';

@pragma('vm:entry-point') // 🔧 Required for background isolate
Future<void> routineBackgroundCheck() async {
  print("🔄 routineBackgroundCheck() triggered");
  print("⏰ Background routine check started");
  // 🔧 Must initialize Firebase inside background isolate
  try {
    await Firebase.initializeApp();
  } catch (e) {
    print("❌ Firebase init failed: $e");
    return;
  }
  // 🔧 Load UID from SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  final uid = prefs.getString('uid') ?? '';
  if (uid.isEmpty) {
    print("⚠️ UID is missing");
    return;
  }

  final now = DateTime.now();
  final today = DateFormat('EEE').format(now); // Mon, Tue, etc.

  try {
    final routines = await FirebaseFirestore.instance
        .collection('routine')
        .where('userId', isEqualTo: uid)
        .where('enabled', isEqualTo: true) // filter only enabled routines
        .get();

    for (var doc in routines.docs) {
      final data = doc.data();
      final List days = data['days'] ?? [];
      final List devices = data['selectedDevices'] ?? [];

      if (!days.contains(today)) continue;
      print("✅ Day matches for routine: ${data['title']}");

      final DateTime? start = DateTime.tryParse(data['startTime']);
      final DateTime? end = DateTime.tryParse(data['endTime']);
      if (start == null || end == null) {
        print("⚠️ Invalid time format for routine: ${data['title']}");
        continue;
      }

      final nowTime = DateTime(now.year, now.month, now.day, now.hour, now.minute);
      final startTime = DateTime(now.year, now.month, now.day, start.hour, start.minute);
      final endTime = DateTime(now.year, now.month, now.day, end.hour, end.minute);

      if (nowTime.isAfter(startTime) && nowTime.isBefore(endTime)) {
        // final key = 'last_trigger_${doc.id}';
        // final lastTriggeredMillis = prefs.getInt(key);
        // final lastTriggered = lastTriggeredMillis != null
        //     ? DateTime.fromMillisecondsSinceEpoch(lastTriggeredMillis)
        //     : null;
        //
        DateTime? lastTriggered;
        if (data.containsKey('lastTriggered')) {
          lastTriggered = DateTime.tryParse(data['lastTriggered']);
        }
        if (lastTriggered != null) {
          print("🔁 Already triggered recently for ${data['title']}");
          continue;
        }

        NotificationService
            .showInstantNotification(
        "Notification",
        "Your routine ${data['title']} ready to start");

        print("⏳ Time within routine window for: ${data['title']}");
        final server = 'broker.sensorsatwork.com';
        final port = 1883;
        final username = 'appuser';
        final password = 'Pulsar-123#';
        final client = MqttServerClient(server, '');
        client.logging(on: false);
        client.port = port;
        client.secure = false;
        client.setProtocolV311();
        client.keepAlivePeriod = 20;
        client.autoReconnect = true;
        try {
          await client.connect(username, password);
          if (client.connectionStatus!.state != MqttConnectionState.connected) {
            print('❌ MQTT connection failed: ${client.connectionStatus}');
            continue;
          }
          for (var device in devices) {
            final String deviceName = device['name'];
            final String roomName = device['value'];
            final String topic = 'users/$uid/room/$roomName/$deviceName';

            final builder = MqttClientPayloadBuilder();
            builder.addString('1');
            client.publishMessage(topic, MqttQos.atMostOnce, builder.payload!, retain: true);
            print("📤 Published '1' to $topic");
          }
          // await prefs.setInt(key, now.millisecondsSinceEpoch); // Save trigger time
          await FirebaseFirestore.instance.collection('routine').doc(doc.id).update({
            'lastTriggered': now.toIso8601String(),
          });
          client.disconnect();
        } catch (e) {
          print("❌ MQTT publish failed: $e");
        }
      } else {
        print("🕓 Routine time not matched for: ${data['title']}");
      }
    }
  } catch (e) {
    print("❌ Firestore fetch error: $e");
  }
}
