import 'package:flutter/material.dart';
import 'package:peraco/core/constants/colors.dart';
import 'package:peraco/core/constants/text_styles.dart';

class DriverHistoryScreen extends StatelessWidget {
  const DriverHistoryScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: SafeArea(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 12), child: Text('Historial', style: PeraCoText.h2(context))),
      Expanded(child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.history, size: 72, color: PeraCoColors.primaryLight.withOpacity(0.5)),
        const SizedBox(height: 16),
        Text('Sin entregas completadas', style: PeraCoText.body(context).copyWith(color: PeraCoColors.textSecondary)),
      ]))),
    ])));
  }
}
