import 'package:flutter/material.dart';
import 'package:peraco/core/constants/colors.dart';
import 'package:peraco/core/constants/text_styles.dart';
import 'package:peraco/features/farmer/crops/data/crops_data.dart';
import 'package:peraco/features/farmer/crops/widgets/crop_detail_sheet.dart';

class FarmerCropsScreen extends StatefulWidget {
  const FarmerCropsScreen({super.key});

  @override
  State<FarmerCropsScreen> createState() => _FarmerCropsScreenState();
}

class _FarmerCropsScreenState extends State<FarmerCropsScreen> {
  String _search = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final filtered = _search.isEmpty ? cropsData
        : cropsData.where((c) => c.nombre.toLowerCase().contains(_search.toLowerCase())).toList();

    return Scaffold(
      backgroundColor: PeraCoColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Guia de Cultivos', style: PeraCoText.h3(context)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _search = v),
                style: PeraCoText.body(context),
                decoration: InputDecoration(
                  hintText: 'Buscar cultivo...',
                  prefixIcon: const Icon(Icons.search, color: PeraCoColors.textHint),
                  suffixIcon: _search.isNotEmpty
                      ? IconButton(icon: const Icon(Icons.close), onPressed: () { _searchCtrl.clear(); setState(() => _search = ''); })
                      : null,
                  filled: true, fillColor: PeraCoColors.surfaceVariant,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              )),
        ),
      ),
      body: filtered.isEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.search_off, size: 48, color: PeraCoColors.textHint),
              const SizedBox(height: 12),
              Text('No se encontro "$_search"', style: PeraCoText.body(context).copyWith(color: PeraCoColors.textSecondary)),
            ]))
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.85),
              itemCount: filtered.length,
              itemBuilder: (context, i) => _CropCard(crop: filtered[i]),
            ),
    );
  }
}

class _CropCard extends StatelessWidget {
  final CropInfo crop;
  const _CropCard({required this.crop});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final inSeason = crop.mesesSiembra.contains(now.month);

    return GestureDetector(
      onTap: () => CropDetailSheet.show(context, crop),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: inSeason ? crop.color.withValues(alpha: 0.3) : PeraCoColors.divider),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(crop.emoji, style: const TextStyle(fontSize: 36)),
            if (inSeason)
              Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: crop.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                  child: Text('SIEMBRA', style: TextStyle(fontSize: 8, color: crop.color, fontWeight: FontWeight.w700, letterSpacing: 0.5))),
          ]),
          const SizedBox(height: 8),
          Text(crop.nombre, style: PeraCoText.bodyBold(context)),
          const SizedBox(height: 4),
          Text(crop.altitud, style: PeraCoText.caption(context).copyWith(color: PeraCoColors.textSecondary),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          const Spacer(),
          Row(children: [
            Icon(Icons.schedule, size: 12, color: PeraCoColors.textHint),
            const SizedBox(width: 4),
            Expanded(child: Text(crop.diasLabel, style: PeraCoText.caption(context).copyWith(color: PeraCoColors.textHint),
                maxLines: 1, overflow: TextOverflow.ellipsis)),
          ]),
          const SizedBox(height: 6),
          Container(height: 4, decoration: BoxDecoration(
              color: crop.color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(2))),
        ]),
      ),
    );
  }
}
