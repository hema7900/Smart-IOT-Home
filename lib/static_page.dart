import 'dart:convert';
import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StaticsPage extends StatefulWidget {
  final MqttServerClient mqttClient;
  const StaticsPage({Key? key, required this.mqttClient});

  @override
  State<StaticsPage> createState() => _StaticsPageState();
}

class _StaticsPageState extends State<StaticsPage> {
  int touchedIndex = 3;
  List<double> kwhData = [220, 310, 180, 337, 290, 410, 230, 260];
  StreamSubscription? _mqttSubscription;
  Map<String, dynamic> _metrics = {};

  @override
  void initState() {
    super.initState();
    getkwh(); // ⬅️ Load saved data on startup
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

  Future<void> getkwh() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMessage = prefs.getString('last_message_static');
    print("LoGS : $savedMessage");

    if (savedMessage != null) {
      try {
        final data = jsonDecode(savedMessage) as Map<String, dynamic>;
        setState(() {
          _metrics = data.map(
            (key, value) =>
                MapEntry(key, double.tryParse(value.toString()) ?? value),
          );

          final kwhVal = double.tryParse(data['kwh'] ?? '0') ?? 0;
          if (kwhData.length >= 8) kwhData.removeAt(0);
          kwhData.add(kwhVal);
          touchedIndex = kwhData.length - 1;
        });
      } catch (e) {
        print("Error parsing KWH data: $e");
      }
    }
  }

  Future<void> _loadTopicAndSubscribe() async {
    final prefs = await SharedPreferences.getInstance();
    final meterId = prefs.getString('meter_id');
    final topic = '/topic/ems/$meterId';
    final savedMessage = prefs.getString('last_message_static');

    widget.mqttClient.subscribe(topic, MqttQos.atMostOnce);
    _mqttSubscription = widget.mqttClient.updates?.listen((
      List<MqttReceivedMessage<MqttMessage>> c,
    ) async {
      final recMessage = c[0].payload as MqttPublishMessage;
      final Static = MqttPublishPayload.bytesToStringAsString(
        recMessage.payload.message,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_message_static', Static);
      try {
        final data = jsonDecode(Static) as Map<String, dynamic>;

        final kwhVal = double.tryParse(data['kwh'] ?? '0') ?? 0;
        if (kwhData.length >= 8) kwhData.removeAt(0);
        kwhData.add(kwhVal);

        final parsedMetrics = data.map(
          (key, value) =>
              MapEntry(key, double.tryParse(value.toString()) ?? value),
        );

        if (mounted) {
          setState(() {
            _metrics = parsedMetrics;
            touchedIndex = kwhData.length - 1;
          });
        }
      } catch (e) {
        print("MQTT parse error: $e");
      }
    });
  }

  Widget _buildMetricCard(String title, double value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
          const SizedBox(height: 4),
          Text(
            value.toStringAsFixed(2),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  LineChartData get _lineChartData => LineChartData(
    gridData: FlGridData(show: true),
    titlesData: FlTitlesData(show: true),
    borderData: FlBorderData(show: true),
    lineBarsData: [
      LineChartBarData(
        spots:
            kwhData
                .asMap()
                .entries
                .map((e) => FlSpot(e.key.toDouble(), e.value))
                .toList(),
        isCurved: true,
        color: Colors.orange,
        dotData: FlDotData(show: true),
        belowBarData: BarAreaData(show: false),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF181829),
      appBar: AppBar(
        backgroundColor: const Color(0xFF181829),
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: const Text(
          'Statistics',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ToggleButtons(
                    isSelected: [true, false, false, false],
                    selectedColor: Colors.white,
                    color: Colors.white70,
                    fillColor: const Color(0xFFFF9900),
                    borderRadius: BorderRadius.circular(30),
                    children: const [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('Live'),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('Day'),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('Week'),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('Month'),
                      ),
                    ],
                    onPressed: (_) {},
                  ),
                  const SizedBox(height: 24),

                  if (_metrics.isNotEmpty) ...[
                    Text(
                      'Device ID: ${_metrics['id']}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'DG Status: ${_metrics['dg_status']}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Time: ${_metrics['time']}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Uptime: ${_metrics['uptime']}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Dynamically display all metrics
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    // children:
                    //     _metrics.entries.map((entry) {
                    //       final value = entry.value;
                    //       return _buildMetricCard(
                    //         entry.key.toUpperCase(),
                    //         value is num ? value.toDouble() : 0.0,
                    //         Colors.teal,
                    //       );
                    //     }).toList(),
                    children:
                        _metrics.entries
                            .where(
                              (entry) =>
                                  ![
                                    'id',
                                    're',
                                    'time',
                                    'uptime',
                                    'dg_status',
                                  ].contains(entry.key),
                            )
                            .map((entry) {
                              final value = entry.value;
                              return _buildMetricCard(
                                entry.key.toUpperCase(),
                                value is num ? value.toDouble() : 0.0,
                                Colors.teal,
                              );
                            })
                            .toList(),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // Fixed footer button
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: getkwh,
                icon: const Icon(Icons.refresh),
                label: const Text("Refresh Data"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
