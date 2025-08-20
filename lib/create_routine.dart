import 'package:flutter/material.dart';
import 'select_room.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateRoutinePage extends StatefulWidget {
  final MqttServerClient mqttClient;
  final Map<String, dynamic>? existingRoutine;
  const CreateRoutinePage({
    super.key,
    required this.mqttClient,
    this.existingRoutine,
  });

  @override
  State<CreateRoutinePage> createState() => _CreateRoutinePageState();
}

class _CreateRoutinePageState extends State<CreateRoutinePage> {
  TimeOfDay _parseTimeOfDay(String timeString) {
    final parts = timeString.split(" ");
    final timeParts = parts[0].split(":");
    int hour = int.parse(timeParts[0]);
    int minute = int.parse(timeParts[1]);

    if (parts[1].toLowerCase() == 'pm' && hour != 12) {
      hour += 12;
    } else if (parts[1].toLowerCase() == 'am' && hour == 12) {
      hour = 0;
    }

    return TimeOfDay(hour: hour, minute: minute);
  }

  final TextEditingController _scheduleController = TextEditingController();
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  late List<String> selectedDays;
  List<Map<String, dynamic>> selectedDevices = [];

  void showTopSnackBar(
    BuildContext context,
    String message, {
    Duration? duration,
    Color color = Colors.grey,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        dismissDirection: DismissDirection.up,
        duration: duration ?? const Duration(seconds: 2),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(top: 60, left: 16, right: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(
          message,
          style: const TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }

  String? docId; // 🔑 Add this to your state class

  @override
  void initState() {
    super.initState();

    // Log existing routine if present
    if (widget.existingRoutine != null) {
      final routine = widget.existingRoutine!;
      _scheduleController.text = routine['title'] ?? '';
      docId = routine['id']; // ✅ Extract the Firestore doc ID

      final now = DateTime.now();
      // final startDateTime = DateTime(
      //   now.year,
      //   now.month,
      //   now.day,
      //   _startTime!.hour,
      //   _startTime!.minute,
      // );
      // final endDateTime = DateTime(
      //   now.year,
      //   now.month,
      //   now.day,
      //   _endTime!.hour,
      //   _endTime!.minute,
      // );

      if (routine['startTime'] != null) {
        final startDate = DateTime.tryParse(routine['startTime']);
        if (startDate != null) {
          _startTime = TimeOfDay(
            hour: startDate.hour,
            minute: startDate.minute,
          );
        }
      }
      if (routine['endTime'] != null) {
        final endDate = DateTime.tryParse(routine['endTime']);
        if (endDate != null) {
          _endTime = TimeOfDay(hour: endDate.hour, minute: endDate.minute);
        }
      }

      // Load days
      if (routine['days'] != null && routine['days'] is List) {
        selectedDays = List<String>.from(routine['days']);
      } else {
        selectedDays = [];
      }

      // Load selected devices
      if (routine['selectedDevices'] != null &&
          routine['selectedDevices'] is List) {
        selectedDevices = List<Map<String, dynamic>>.from(
          routine['selectedDevices'].map(
            (device) => {'name': device['name'], 'value': device['value']},
          ),
        );
      } else {
        selectedDevices = [];
      }
    } else {
      // Default to current weekday if no routine passed
      final today = DateTime.now();
      final weekdayMap = {
        DateTime.monday: "Mon",
        DateTime.tuesday: "Tue",
        DateTime.wednesday: "Wed",
        DateTime.thursday: "Thu",
        DateTime.friday: "Fri",
        DateTime.saturday: "Sat",
        DateTime.sunday: "Sun",
      };
      selectedDays = [weekdayMap[today.weekday]!];
    }
  }

  @override
  void dispose() {
    _scheduleController.dispose();
    super.dispose();
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Create Routine",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: const BackButton(color: Colors.white),
        actions: [
          TextButton(
            onPressed: () async {
              final scheduleName = _scheduleController.text;
              final now = DateTime.now();
              final startDateTime = DateTime(
                now.year,
                now.month,
                now.day,
                _startTime!.hour,
                _startTime!.minute,
              );
              final endDateTime = DateTime(
                now.year,
                now.month,
                now.day,
                _endTime!.hour,
                _endTime!.minute,
              );

              final startTimeIso = startDateTime.toIso8601String();
              final endTimeIso = endDateTime.toIso8601String();

              if (scheduleName.isEmpty ||
                  startTimeIso == null ||
                  endTimeIso == null ||
                  selectedDays.isEmpty ||
                  selectedDevices.isEmpty) {
                showTopSnackBar(
                  context,
                  "Please complete all fields",
                  color: Colors.red,
                );
                return;
              }

              // Time validation
              final start = DateTime(
                2025,
                1,
                1,
                _startTime!.hour,
                _startTime!.minute,
              );
              final end = DateTime(
                2025,
                1,
                1,
                _endTime!.hour,
                _endTime!.minute,
              );
              if (end.isBefore(start)) {
                showTopSnackBar(
                  context,
                  "End time must be after start time",
                  color: Colors.red,
                );
                return;
              }

              final user = FirebaseAuth.instance.currentUser;
              if (user == null) {
                showTopSnackBar(
                  context,
                  "User not authenticated!",
                  color: Colors.red,
                );
                return;
              }

              final routineData = {
                'userId': user.uid,
                'title': scheduleName,
                'startTime': startTimeIso,
                'endTime': endTimeIso,
                'days': selectedDays,
                'devices': selectedDevices.length,
                'selectedDevices':
                    selectedDevices
                        .map(
                          (device) => {
                            'name': device['name'],
                            'value': device['value'],
                          },
                        )
                        .toList(),
                'createdDate':
                    DateTime.now().toIso8601String(), // For today's filter
              };
              // For now, just print
              // print('Routine Data: $routineData');
              try {
                if (docId != null) {
                  // 🛠 Update existing routine
                  await FirebaseFirestore.instance
                      .collection('routine')
                      .doc(docId)
                      .update(routineData);

                  showTopSnackBar(
                    context,
                    "Routine updated successfully!",
                    color: Colors.green,
                  );
                } else {
                  // ➕ Add new routine
                  await FirebaseFirestore.instance
                      .collection('routine')
                      .add(routineData);

                  showTopSnackBar(
                    context,
                    "Routine created successfully!",
                    color: Colors.green,
                  );
                }
                Navigator.pop(context); // Optionally return data
              } catch (e) {
                showTopSnackBar(
                  context,
                  "Failed to save routine: $e",
                  color: Colors.red,
                );
              }
            },
            child: const Text("SAVE", style: TextStyle(color: Colors.white)),
          ),
        ],
        backgroundColor: Colors.black87,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _buildTextField("Schedule", _scheduleController),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildTimeBox("Start Time", _startTime, true)),
                const SizedBox(width: 16),
                Expanded(child: _buildTimeBox("End Time", _endTime, false)),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              "Select Date",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildDaySelector(),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SelectRoomPage()),
                );

                if (result != null && result is List<Map<String, dynamic>>) {
                  setState(() {
                    selectedDevices = result;
                  });
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text("+ Add Devices"),
            ),

            const SizedBox(height: 16),
            ...selectedDevices
                .map((device) => _buildDeviceTile(device))
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildTimeBox(String label, TimeOfDay? time, bool isStart) {
    return GestureDetector(
      onTap: () => _pickTime(isStart),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          time != null ? time.format(context) : label,
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildDaySelector() {
    final days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children:
          days.map((day) {
            final selected = selectedDays.contains(day);
            return GestureDetector(
              onTap: () {
                setState(() {
                  selected ? selectedDays.remove(day) : selectedDays.add(day);
                });
              },
              child: CircleAvatar(
                backgroundColor: selected ? Colors.orange : Colors.grey[300],
                child: Text(
                  day.substring(0, 1),
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.black,
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildDeviceTile(Map<String, dynamic> device) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.devices),
        title: Text(device['name']),
        subtitle: Text(device['value']),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.grey),
          tooltip: 'Remove Device',
          onPressed: () {
            setState(() {
              selectedDevices.remove(device);
            });
            showTopSnackBar(
              context,
              "${device['name']} removed",
              color: Colors.red,
            );
          },
        ),
      ),
    );
  }
}
