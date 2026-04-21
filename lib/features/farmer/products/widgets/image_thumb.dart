import 'package:flutter/material.dart';
import 'package:peraco/core/constants/colors.dart';
import 'package:peraco/core/constants/text_styles.dart';

class ImageThumb extends StatelessWidget {
  final String url;
  final bool isMain;
  final VoidCallback? onRemove;
  const ImageThumb({super.key, required this.url, this.isMain = false, this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100, height: 100,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: isMain ? Border.all(color: PeraCoColors.primary, width: 2) : null,
        image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
      ),
      child: Stack(children: [
        if (isMain)
          Positioned(
            bottom: 4, left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: PeraCoColors.primary, borderRadius: BorderRadius.circular(4)),
              child: Text('Principal', style: PeraCoText.caption(context).copyWith(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
            ),
          ),
        if (onRemove != null)
          Positioned(
            top: 4, right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                child: const Icon(Icons.close, color: Colors.white, size: 14),
              ),
            ),
          ),
      ]),
    );
  }
}
