import 'package:flutter/material.dart';

class TrackingScreen extends StatelessWidget {
  final String orderId;
  const TrackingScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rastreo')),
      body: Center(child: Text('Rastreo pedido: $orderId')),
    );
  }
}
