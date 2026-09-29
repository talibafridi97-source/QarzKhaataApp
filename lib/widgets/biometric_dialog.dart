import 'package:flutter/material.dart';

/// Professional Biometric Fingerprint Scan Dialog for mobile and desktop testing.
class BiometricDialog extends StatelessWidget {
  const BiometricDialog({super.key});

  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const BiometricDialog(),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.fingerprint_rounded, color: Color(0xFF1E3C72), size: 28),
          SizedBox(width: 10),
          Text('Fingerprint Verification', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.indigo.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.touch_app_rounded,
              size: 54,
              color: Color(0xFF1E3C72),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Place your finger on the sensor to verify your identity and secure your Qarz Khaata.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 10),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel', style: TextStyle(color: Colors.red)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E3C72),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () {
            // Simulate successful fingerprint scan
            Navigator.pop(context, true);
          },
          child: const Text('Scan Fingerprint'),
        ),
      ],
    );
  }
}
