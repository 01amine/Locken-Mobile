🔐 Data Center Security App
A Flutter-based mobile application that ensures physical security in a data center environment. The app uses BLE signals to interact with smart locks, performs facial recognition for user verification, and communicates with a backend system to manage access control and security events.

🚀 Features
BLE Smart Lock Detection
Automatically scans for nearby BLE smart locks and retrieves their UUIDs.

Facial Recognition Access Control
Captures the user’s face and sends it along with the smart lock UUID and user ID to the backend to verify access permissions.

Smart Lock Control
If the user has access, the smart lock is automatically opened.

Security Threats Dashboard
Displays real-time security threats detected by the system.

Access Logs Viewer
View detailed logs of all access attempts and security-related events.

🧠 How It Works
The app scans for BLE signals to detect nearby smart locks and obtain their UUIDs.

The user’s face is scanned using the device camera.

The app sends the scanned face image, smart lock UUID, and user ID to the backend API.

The backend verifies if the user has access to the lock.

If verified, the smart lock is triggered to open.

The system logs the access and updates the security dashboard if necessary.

🛠️ Tech Stack
Flutter – Cross-platform UI toolkit

BLE (Bluetooth Low Energy) – Used to detect smart lock UUIDs

Camera and Face Detection – For capturing and verifying user identity

REST API – To communicate with the backend for access validation


