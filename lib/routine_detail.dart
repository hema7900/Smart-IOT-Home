import 'package:flutter/material.dart';

class RoutineDetailPage extends StatelessWidget {
  final Map<String, dynamic> routine;

  const RoutineDetailPage({super.key, required this.routine});

  static const List<Map<String, String>> deviceImageMap = [
    {'name': 'Exhaust Fan', 'image': 'assets/exhaust.jpg'},
    {'name': 'Ceiling Light', 'image': 'assets/ceiling.jpg'},
    {'name': 'Cabinet Lights', 'image': 'assets/cabinet.jpg'},
    {'name': 'Water Purifier', 'image': 'assets/purifier.jpg'},
    {'name': 'Fan', 'image': 'assets/fan.jpg'},
    {'name': 'AC', 'image': 'assets/ac.jpg'},
    {'name': 'Bulb', 'image': 'assets/bulb.jpg'},
  ];

  @override
  Widget build(BuildContext context) {
    final String title = routine['title'] ?? 'Untitled';
    final String startTime = routine['startTime'] ?? '--:--';
    final String endTime = routine['endTime'] ?? '--:--';
    final int devices = routine['devices'] ?? 0;
    final List days = routine['days'] ?? [];
    final List selectedDevices = routine['selectedDevices'] ?? [];

    final Map<String, List<Map<String, dynamic>>> roomDeviceMap = {};

    // 🔽 Print selected device names
    for (var device in selectedDevices) {
      final room = device['value'] ?? 'Unknown';
      roomDeviceMap.putIfAbsent(room, () => []).add(device);
      print("📦 Selected device: ${device['name']} (${device['value']})");
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: const BackButton(color: Colors.white),
        backgroundColor: Colors.black87,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _buildInfoTile("Start Time", startTime),
            _buildInfoTile("End Time", endTime),
            const SizedBox(height: 16),
            const Text(
              "Scheduled Days",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildDayDisplay(days),
            const SizedBox(height: 24),
            Text(
              "Devices ($devices)",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: selectedDevices.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
              ),
              itemBuilder: (context, index) {
                final device = selectedDevices[index];
                return _buildDeviceTile(device);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  Widget _buildDayDisplay(List days) {
    final allDays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children:
          allDays.map((day) {
            final selected = days.contains(day);
            return CircleAvatar(
              backgroundColor: selected ? Colors.orange : Colors.grey[300],
              child: Text(
                day.substring(0, 1),
                style: TextStyle(color: selected ? Colors.white : Colors.black),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildDeviceTile(Map<String, dynamic> device) {
    final String name = device['name'] ?? 'Unknown Device';
    final String room = device['value'] ?? 'Unknown Room';

    final match = deviceImageMap.firstWhere(
      (item) => item['name']?.toLowerCase() == name.toLowerCase(),
      orElse: () => {},
    );
    final String? image = match['image'];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child:
              image != null
                  ? Image.asset(
                    image,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  )
                  : Container(
                    width: 100,
                    height: 100,
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.devices,
                      size: 40,
                      color: Colors.grey,
                    ),
                  ),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        Text(
          room,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}
