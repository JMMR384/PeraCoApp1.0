import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:peraco/core/constants/colors.dart';
import 'package:peraco/core/constants/text_styles.dart';
import 'package:peraco/shared/providers/app_update_provider.dart';

class UpdateDialog extends StatelessWidget {
  final AppUpdate update;
  const UpdateDialog({super.key, required this.update});

  Future<void> _download() async {
    final uri = Uri.parse(update.downloadUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !update.forceUpdate,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: PeraCoColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.system_update_outlined, color: PeraCoColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Nueva versión', style: PeraCoText.bodyBold(context)),
              Text('v${update.version}', style: PeraCoText.caption(context).copyWith(color: PeraCoColors.textSecondary)),
            ]),
          ),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 12),
          if (update.changelogEs != null && update.changelogEs!.isNotEmpty) ...[
            Text('Novedades', style: PeraCoText.bodyBold(context)),
            const SizedBox(height: 6),
            Text(update.changelogEs!, style: PeraCoText.body(context)),
            const SizedBox(height: 16),
          ],
          if (update.forceUpdate)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: PeraCoColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: PeraCoColors.warning.withValues(alpha: 0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.warning_amber_outlined, size: 16, color: PeraCoColors.warning),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Esta actualización es obligatoria.',
                    style: PeraCoText.caption(context).copyWith(color: PeraCoColors.warning),
                  ),
                ),
              ]),
            ),
          const SizedBox(height: 16),
        ]),
        actions: [
          if (!update.forceUpdate)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Más tarde', style: TextStyle(color: PeraCoColors.textSecondary)),
            ),
          ElevatedButton.icon(
            onPressed: _download,
            icon: const Icon(Icons.download_outlined),
            label: const Text('Actualizar ahora'),
            style: ElevatedButton.styleFrom(
              backgroundColor: PeraCoColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}
