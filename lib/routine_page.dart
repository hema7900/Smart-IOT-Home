import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:convert'; // make sure it's imported
import 'package:firebase_auth/firebase_auth.dart';
import 'create_routine.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'routine_detail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'noti.dart';

class RoutinePage extends StatefulWidget {
  final MqttServerClient mqttClient;
  const RoutinePage({Key? key, required this.mqttClient}) : super(key: key);

  @override
  State<RoutinePage> createState() => _RoutinePageState();
}

class _RoutinePageState extends State<RoutinePage>
    with SingleTickerProviderStateMixin {
  Map<String, bool> routineSwitchStates = {};
  late TabController _tabController;
  File? _profileImage;
  String userName = '';
  bool isSelectionMode = false;
  Set<String> selectedRoutineIds = {};
  List<Map<String, dynamic>> allRoutines = [];

  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
    _loadUserName();
    _loadProfileImageFromPrefs();
    _loadRoutineSwitchStates();
    super.initState();
  }

  Future<void> _loadUserName() async {
    User? user = FirebaseAuth.instance.currentUser;
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

  Future<void> _saveRoutineSwitchStates() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'routine_switch_states',
      jsonEncode(routineSwitchStates),
    );
  }

  Future<void> _loadRoutineSwitchStates() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('routine_switch_states');
    if (stored != null) {
      final Map<String, dynamic> jsonMap = jsonDecode(stored);
      setState(() {
        routineSwitchStates = jsonMap.map(
          (key, value) => MapEntry(key, value as bool),
        );
      });
    }
  }

  void _toggleSelection(String id) {
    setState(() {
      if (selectedRoutineIds.contains(id)) {
        selectedRoutineIds.remove(id);
      } else {
        selectedRoutineIds.add(id);
      }
      isSelectionMode = selectedRoutineIds.isNotEmpty;
    });
  }

  void _clearSelection() {
    setState(() {
      selectedRoutineIds.clear();
      isSelectionMode = false;
    });
  }

  void _selectAll(List<Map<String, dynamic>> routines) {
    setState(() {
      selectedRoutineIds = routines.map((e) => e['id'] as String).toSet();
      isSelectionMode = true;
    });
  }

  void _deleteSelected() async {
    for (var id in selectedRoutineIds) {
      await FirebaseFirestore.instance.collection('routine').doc(id).delete();
    }
    _clearSelection();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Deleted selected routines"),
        backgroundColor: Colors.red, // 🔴 Red background
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF181829),
      appBar: AppBar(
        backgroundColor: const Color(0xFF181829),
        elevation: 0,
        leading:
            isSelectionMode
                ? IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: _clearSelection,
                )
                : const BackButton(color: Colors.white),
        title:
            isSelectionMode
                ? Text(
                  '${selectedRoutineIds.length} selected',
                  style: const TextStyle(color: Colors.white),
                )
                : const Text(
                  'Routines',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        actions:
            isSelectionMode
                ? [
                  TextButton(
                    onPressed: () => _selectAll(allRoutines),
                    child: const Text(
                      "Select All",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ]
                : [
                  Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.white,
                      backgroundImage:
                          _profileImage != null
                              ? FileImage(_profileImage!)
                              : null,
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
                  ),
                ],
      ),

      body: Column(
        children: [
          // Tab Bar
          Container(
            color: const Color(0xFF181829),
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.orange,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey,
              tabs: const [Tab(text: "ALL"), Tab(text: "TODAY")],
            ),
          ),

          // TabBarView Content
          Expanded(
            child: Container(
              color:
                  Colors.white, // 👈 this makes the area under the tabs white
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildRoutineStream(all: true),
                  _buildRoutineStream(all: false),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => CreateRoutinePage(mqttClient: widget.mqttClient),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar:
          isSelectionMode
              ? Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 20,
                ),
                child:
                    selectedRoutineIds.length > 1
                        ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.grey,
                                size: 28,
                              ),
                              onPressed: _deleteSelected,
                              tooltip: 'Delete Selected',
                            ),
                          ],
                        )
                        : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.grey),
                              onPressed: () async {
                                final selectedId = selectedRoutineIds.first;
                                final doc =
                                    await FirebaseFirestore.instance
                                        .collection('routine')
                                        .doc(selectedId)
                                        .get();
                                if (doc.exists) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => CreateRoutinePage(
                                            mqttClient: widget.mqttClient,
                                            existingRoutine: {
                                              ...doc.data()!,
                                              'id': doc.id,
                                            },
                                          ),
                                    ),
                                  );
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.drive_file_rename_outline,
                                color: Colors.grey,
                              ),
                              onPressed: () async {
                                final selectedId = selectedRoutineIds.first;
                                final doc =
                                    await FirebaseFirestore.instance
                                        .collection('routine')
                                        .doc(selectedId)
                                        .get();
                                if (doc.exists) {
                                  final TextEditingController controller =
                                      TextEditingController(text: doc['title']);
                                  showDialog(
                                    context: context,
                                    builder:
                                        (ctx) => AlertDialog(
                                          title: const Text("Rename Routine"),
                                          content: TextField(
                                            controller: controller,
                                            decoration: const InputDecoration(
                                              hintText: 'New title',
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed:
                                                  () => Navigator.pop(ctx),
                                              child: const Text("Cancel"),
                                            ),
                                            TextButton(
                                              onPressed: () async {
                                                await FirebaseFirestore.instance
                                                    .collection('routine')
                                                    .doc(selectedId)
                                                    .update({
                                                      'title': controller.text,
                                                    });
                                                Navigator.pop(ctx);
                                                _clearSelection();
                                              },
                                              child: const Text("Rename"),
                                            ),
                                          ],
                                        ),
                                  );
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.grey,
                              ),
                              onPressed: _deleteSelected,
                            ),
                          ],
                        ),
              )
              : null,
    );
  }

  Widget _buildRoutineStream({required bool all}) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('User not authenticated.'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('routine')
              .where('userId', isEqualTo: user.uid)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No routines found.'));
        }

        List<Map<String, dynamic>> routines =
            snapshot.data!.docs
                .map(
                  (doc) => {
                    ...doc.data() as Map<String, dynamic>,
                    'id': doc.id,
                  },
                )
                .toList();

        if (!all) {
          final now = DateTime.now();
          final todayStart = DateTime(now.year, now.month, now.day);
          final todayEnd = todayStart.add(const Duration(days: 1));
          routines =
              routines.where((r) {
                final String? dateStr = r['createdDate'];
                if (dateStr == null) return false;
                final created = DateTime.tryParse(dateStr);
                if (created == null) return false;
                return created.isAfter(todayStart) &&
                    created.isBefore(todayEnd);
              }).toList();
        }
        allRoutines = routines;

        return _buildRoutineList(routines);
      },
    );
  }

  Widget _buildRoutineList(List<Map<String, dynamic>> routines) {
    String formatTimeRange(String startIso, String endIso) {
      final start = DateTime.tryParse(startIso);
      final end = DateTime.tryParse(endIso);
      if (start == null || end == null) return '';

      final formatter = DateFormat.jm(); // Example: 3:00 PM
      return '${formatter.format(start)} - ${formatter.format(end)}';
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: routines.length,
      itemBuilder: (context, index) {
        final routine = routines[index];
        final isSelected = selectedRoutineIds.contains(routine['id']);
        return GestureDetector(
          onLongPress: () => _toggleSelection(routine['id']),
          onTap:
              isSelectionMode
                  ? () => _toggleSelection(routine['id'])
                  : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RoutineDetailPage(routine: routine),
                      ),
                    );
                  },
          child: Card(
            color: isSelected ? Colors.orange.shade100 : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              title: Text(
                routine['title'] ?? 'Untitled',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 16, color: Colors.grey),
                      // const SizedBox(width: 2),
                      Text(
                        formatTimeRange(
                          routine['startTime'],
                          routine['endTime'],
                        ),
                        style: const TextStyle(color: Colors.black87),
                      ),

                      const SizedBox(width: 10),
                      const Icon(Icons.devices, size: 16, color: Colors.grey),
                      // const SizedBox(width: 4),
                      Text(
                        '${routine['devices']} devices',
                        style: const TextStyle(color: Colors.black87),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          (() {
                            final days =
                                routine['days'] as List<dynamic>? ?? [];
                            if (days.length == 7) return 'Everyday';
                            return days.join(', ');
                          })(),
                          style: const TextStyle(color: Colors.black87),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // trailing: Switch(
              //   onChanged: (val) {

              //   },
              //   activeColor: Colors.orange,
              // ),
              trailing: StatefulBuilder(
                builder: (context, setSwitchState) {
                  final routineId = routine['id'] as String;
                  final isOn = routineSwitchStates[routineId] ?? false;
                  final String title = routine['title'] ?? 'Untitled';
                  final days = routine['days'] ?? [];
                  final startTime = routine['startTime'] ?? '';
                  final endTime = routine['endTime'] ?? '';
                  final List<dynamic> devices =
                      routine['selectedDevices'] ?? [];
                  final String today = DateFormat('EEE').format(DateTime.now());
                  final now = DateTime.now();
                  return Switch(
                    value: isOn,
                    onChanged: (value) async {
                      // NotificationService
                      //     .showInstantNotification(
                      //     "Notification",
                      //     "Your routine ${routine['title']} enabled");

                      //   setState(() {
                      //     routineSwitchStates[routineId] = value;
                      //   });
                      //   await _saveRoutineSwitchStates(); // ✅ Save after change
                      //   final DateTime now = DateTime.now();
                      //   final DateTime? start = DateTime.tryParse(startTime);
                      //   final DateTime? end = DateTime.tryParse(endTime);
                      //   final String today = DateFormat('EEE').format(now);
                      //   final String uid =
                      //       FirebaseAuth.instance.currentUser?.uid ?? '';
                      //
                      //   debugPrint("Start Time: $startTime");
                      //   debugPrint("End Time: $endTime");
                      //   debugPrint(
                      //     "🕓 Current Time: ${DateFormat.jm().format(now)}",
                      //   );
                      //
                      //   if (!value) {
                      //     debugPrint("🔕 Routine Turned OFF: $routineId");
                      //     for (var device in devices) {
                      //       final String deviceName = device['name'] ?? '';
                      //       final String roomName = device['value'] ?? '';
                      //       final String topic =
                      //           'users/$uid/room/$roomName/$deviceName';
                      //       const String message = '0'; // Turn ON
                      //
                      //       final builder = MqttClientPayloadBuilder();
                      //       builder.addString(message);
                      //
                      //       try {
                      //         widget.mqttClient.publishMessage(
                      //           topic,
                      //           MqttQos.atMostOnce,
                      //           builder.payload!,
                      //           retain: true,
                      //         );
                      //         debugPrint('✅ Published to $topic: $message');
                      //       } catch (e) {
                      //         debugPrint('❌ Error publishing MQTT message: $e');
                      //       }
                      //     }
                      //     return;
                      //   }
                      //
                      //   if (!days.contains(today)) {
                      //     debugPrint("❌ Day does not match");
                      //     return;
                      //   }
                      //
                      //   debugPrint("✅ Day is same");
                      //   if (start != null && end != null) {
                      //     final startToday = DateTime(
                      //       now.year,
                      //       now.month,
                      //       now.day,
                      //       start.hour,
                      //       start.minute,
                      //     );
                      //     final endToday = DateTime(
                      //       now.year,
                      //       now.month,
                      //       now.day,
                      //       end.hour,
                      //       end.minute,
                      //     );
                      //
                      //     if (now.isAfter(startToday) && now.isBefore(endToday)) {
                      //       debugPrint("✅ Time is between start and end");
                      //
                      //       // ✅ Publish message to each selected device
                      //       debugPrint("Devices:");
                      //       for (var device in devices) {
                      //         final String deviceName = device['name'] ?? '';
                      //         final String roomName = device['value'] ?? '';
                      //         final String topic =
                      //             'users/$uid/room/$roomName/$deviceName';
                      //         const String message = '1'; // Turn ON
                      //
                      //         final builder = MqttClientPayloadBuilder();
                      //         builder.addString(message);
                      //
                      //         try {
                      //           widget.mqttClient.publishMessage(
                      //             topic,
                      //             MqttQos.atMostOnce,
                      //             builder.payload!,
                      //             retain: true,
                      //           );
                      //           debugPrint('✅ Published to $topic: $message');
                      //         } catch (e) {
                      //           debugPrint('❌ Error publishing MQTT message: $e');
                      //         }
                      //       }
                      //     } else {
                      //       debugPrint("❌ Time is NOT between start and end");
                      //     }
                      //   } else {
                      //     debugPrint("⚠️ Invalid start or end time format");
                      //   }
                      //   onChanged: (value) async {
                      setState(() {
                        routineSwitchStates[routineId] = value;
                      });
                      await _saveRoutineSwitchStates(); // Optional: for local UI state
                      // ✅ Update routine `enabled` field in Firestore
                      await FirebaseFirestore.instance
                          .collection('routine')
                          .doc(routineId)
                          .update({'enabled': value});
                      // ✅ Store UID for background access
                      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('uid', uid);
                      debugPrint(
                        "🔁 Routine $routineId ${value ? 'enabled' : 'disabled'}",
                      );
                      if (!value) {
                        // NotificationService
                        //     .showInstantNotification(
                        //     "Notification",
                        //     "Your routine ${routine['title']} disabled");

                        await FirebaseFirestore.instance
                            .collection('routine')
                            .doc(routineId)
                            .update({
                              'enabled': value,
                              if (!value)
                                'lastTriggered':
                                    FieldValue.delete(), // clear it when disabled
                            });

                        // 🚨 Routine disabled — immediately send '0' to all devices
                        for (var device in devices) {
                          final String deviceName = device['name'] ?? '';
                          final String roomName = device['value'] ?? '';
                          final String topic =
                              'users/$uid/room/$roomName/$deviceName';
                          const String message = '0';

                          final builder = MqttClientPayloadBuilder();
                          builder.addString(message);

                          try {
                            widget.mqttClient.publishMessage(
                              topic,
                              MqttQos.atMostOnce,
                              builder.payload!,
                              retain: true,
                            );
                            debugPrint('📴 Sent "0" to $topic');
                          } catch (e) {
                            debugPrint('❌ MQTT publish error: $e');
                          }
                        }
                      } else {
                        // ✅ Immediately run background routine check after enabling
                        routineBackgroundCheck(); // 👈 directly trigger it
                        await FirebaseFirestore.instance
                            .collection('routine')
                            .doc(routineId)
                            .update({'enabled': true});
                      }
                    },

                    // },
                    activeColor: Colors.orange,
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
