import 'package:flutter/material.dart';
import 'Room/bedroom.dart';
import 'Room/kitchen.dart';
import 'Room/living_room.dart';
import 'Room/study_room.dart';

class SelectRoomPage extends StatefulWidget {
  const SelectRoomPage({super.key});

  @override
  State<SelectRoomPage> createState() => _SelectRoomPageState();
}

class _SelectRoomPageState extends State<SelectRoomPage> {
  final Map<String, List<Map<String, dynamic>>> roomDevices = {
    'Kitchen': [
      {'name': 'Exhaust Fan', 'image': 'assets/exhaust.jpg'},
      {'name': 'Ceiling Light', 'image': 'assets/ceiling.jpg'},
      {'name': 'Cabinet Lights', 'image': 'assets/cabinet.jpg'},
      {'name': 'Water Purifier', 'image': 'assets/purifier.jpg'},
    ],
    'Bedroom': [
      {'name': 'Fan', 'image': 'assets/fan.jpg'},
      {'name': 'AC', 'image': 'assets/ac.jpg'},
      {'name': 'Ceiling Light', 'image': 'assets/ceiling.jpg'},
      {'name': 'Bulb', 'image': 'assets/bulb.jpg'},
    ],
    'Study': [
      {'name': 'Fan', 'image': 'assets/fan.jpg'},
      {'name': 'AC', 'image': 'assets/ac.jpg'},
      {'name': 'Ceiling Light', 'image': 'assets/ceiling.jpg'},
      {'name': 'Bulb', 'image': 'assets/bulb.jpg'},
    ],
    'Living': [
      {'name': 'Fan', 'image': 'assets/fan.jpg'},
      {'name': 'AC', 'image': 'assets/ac.jpg'},
      {'name': 'Ceiling Light', 'image': 'assets/ceiling.jpg'},
      {'name': 'Bulb', 'image': 'assets/bulb.jpg'},
    ],
  };

  final List<Map<String, dynamic>> selected = [];

  void toggleDevice(Map<String, dynamic> device, String room) {
    final entry = {'name': device['name'], 'value': room, 'enabled': true};

    setState(() {
      final exists = selected.any(
        (d) => d['name'] == entry['name'] && d['value'] == entry['value'],
      );
      if (exists) {
        selected.removeWhere(
          (d) => d['name'] == entry['name'] && d['value'] == entry['value'],
        );
      } else {
        selected.add(entry);
      }
    });
  }

  bool isSelected(Map<String, dynamic> device, String room) {
    return selected.any(
      (d) => d['name'] == device['name'] && d['value'] == room,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Select Devices',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: const BackButton(color: Colors.white),
        backgroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.white),
            onPressed: () => Navigator.pop(context, selected),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children:
              roomDevices.entries.map((entry) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: entry.value.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 1.2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                      itemBuilder: (context, index) {
                        final device = entry.value[index];
                        final isSelectedDevice = isSelected(device, entry.key);

                        return GestureDetector(
                          onTap: () => toggleDevice(device, entry.key),
                          child: Container(
                            decoration: BoxDecoration(
                              color:
                                  isSelectedDevice
                                      ? Colors.orange.shade100
                                      : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    isSelectedDevice
                                        ? Colors.orange
                                        : Colors.grey.shade300,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.asset(
                                      device['image'],
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    device['name'],
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                );
              }).toList(),
        ),
      ),
    );
  }
}
