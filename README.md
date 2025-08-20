Smart IoT Home Automation App

A cross-platform Flutter app for controlling home devices and monitoring energy usage in real-time using ESP32, MQTT, and IoT sensors.

Features

Real-time Device Control: Control relays connected to lights, fans, and other appliances via MQTT.

Notifications: Receive instant alerts for device status or energy thresholds.

Energy Meter Monitoring: View live energy consumption with your connected energy meter.

Multiple Rooms & Devices: Organize devices by rooms and control them individually.

Automation Routines: Schedule tasks or create automation rules for smarter home management.

Home & Weather Overview: Get a quick glance at overall home status and local weather.

Tech Stack

Frontend: Flutter (Dart)

IoT & Backend: ESP32 + MQTT

Database / Notifications: Firebase 

Setup & Installation

Clone the repository:

git clone https://github.com/hema7900/Smart-IOT-Home.git
cd Smart-IOT-Home
Install dependencies:
flutter pub get

Configure MQTT:
Update the MQTT broker details in lib/config.dart or wherever the broker is initialized.

Run the app:

flutter run

How It Works

MQTT Communication:

App subscribes to topics for real-time device status.

Commands from the app are published to the corresponding relay topic.

Notifications:

Alerts users when devices change state or energy usage exceeds limits.

Energy Meter Data:

ESP32 reads meter data and sends it to the app over MQTT for real-time monitoring.


Future Improvements

Voice control (Google Assistant / Alexa)

Advanced automation rules (IFTTT-style)

Historical energy consumption graphs

License

This project is open-source under the MIT License
.
