import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peraco/core/constants/colors.dart';
import 'package:peraco/core/constants/text_styles.dart';
import 'package:peraco/features/farmer/crops/data/crops_data.dart';
import 'package:peraco/features/farmer/crops/providers/harvest_provider.dart';

class HarvestFormSheet extends ConsumerStatefulWidget {
  final String? preselectedCrop;
  const HarvestFormSheet({super.key, this.preselectedCrop});

  static void show(BuildContext context, {String? preselectedCrop}) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => HarvestFormSheet(preselectedCrop: preselectedCrop),
    );
  }

  @override
  ConsumerState<HarvestFormSheet> createState() => _HarvestFormSheetState();
}

class _HarvestFormSheetState extends ConsumerState<HarvestFormSheet> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedCrop;
  DateTime? _fechaSiembra;
  DateTime? _fechaCosecha;
  final _cantidadCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _fertilizanteCtrl = TextEditingController();
  final _notasCtrl = TextEditingController();
  String _unidad = 'kg';
  String? _tipoSuelo;
  String? _phDesc;
  bool _loading = false;
  bool _showAgro = false; // sección agronómica expandible

  final _unidades = ['kg', 'ton', 'lb', 'canastillas', 'costales', 'unidades'];

  @override
  void initState() {
    super.initState();
    _selectedCrop = widget.preselectedCrop;
    // Pre-cargar datos agronómicos si hay cultivo preseleccionado
    if (_selectedCrop != null) {
      final crop = cropsData.where((c) => c.nombre == _selectedCrop).firstOrNull;
      if (crop != null) {
        _tipoSuelo = crop.tiposSuelo.first;
      }
    }
  }

  @override
  void dispose() {
    _cantidadCtrl.dispose();
    _areaCtrl.dispose();
    _fertilizanteCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _pickDate({required bool isCosecha}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isCosecha ? now.add(const Duration(days: 90)) : now,
      firstDate: isCosecha ? now : now.subtract(const Duration(days: 365)),
      lastDate: DateTime(now.year + 3),
      builder: (ctx, child) => Theme(
          data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: PeraCoColors.primary)),
          child: child!),
    );
    if (picked != null) setState(() => isCosecha ? _fechaCosecha = picked : _fechaSiembra = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fechaCosecha == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona la fecha de cosecha estimada')));
      return;
    }
    setState(() => _loading = true);
    final success = await ref.read(harvestProvider.notifier).add(
      cultivoNombre: _selectedCrop!,
      fechaSiembra: _fechaSiembra,
      fechaCosechaEstimada: _fechaCosecha!,
      cantidadEstimada: _cantidadCtrl.text.isNotEmpty ? double.tryParse(_cantidadCtrl.text) : null,
      unidad: _unidad,
      areaHa: _areaCtrl.text.isNotEmpty ? double.tryParse(_areaCtrl.text) : null,
      tipoSuelo: _tipoSuelo,
      phDesc: _phDesc,
      fertilizante: _fertilizanteCtrl.text.isNotEmpty ? _fertilizanteCtrl.text.trim() : null,
      notas: _notasCtrl.text.isNotEmpty ? _notasCtrl.text.trim() : null,
    );
    setState(() => _loading = false);
    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Cosecha registrada'),
          backgroundColor: PeraCoColors.success, behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
    }
  }

  // Cuando cambia el cultivo, sugerir tipo de suelo ideal
  void _onCropChanged(String? v) {
    setState(() {
      _selectedCrop = v;
      if (v != null) {
        final crop = cropsData.where((c) => c.nombre == v).firstOrNull;
        if (crop != null && _tipoSuelo == null) {
          _tipoSuelo = crop.tiposSuelo.first;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedCropInfo = _selectedCrop != null
        ? cropsData.where((c) => c.nombre == _selectedCrop).firstOrNull
        : null;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: SingleChildScrollView(child: Form(key: _formKey, child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, decoration: BoxDecoration(color: PeraCoColors.divider, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        Row(children: [
          Text('Registrar cosecha', style: PeraCoText.h3(context)),
          const Spacer(),
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
        ]),
        const SizedBox(height: 16),

        // ── Cultivo ──
        DropdownButtonFormField<String>(
          value: _selectedCrop,
          decoration: const InputDecoration(hintText: 'Selecciona el cultivo', prefixIcon: Icon(Icons.eco_outlined)),
          items: cropsData.map((c) => DropdownMenuItem(value: c.nombre, child: Row(children: [
            Text(c.emoji), const SizedBox(width: 8), Text(c.nombre),
          ]))).toList(),
          validator: (v) => v == null ? 'Selecciona un cultivo' : null,
          onChanged: _onCropChanged,
        ),

        // Sugerencia NPK si hay cultivo seleccionado
        if (selectedCropInfo != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: PeraCoColors.greenPastel, borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              const Text('🧪', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 8),
              Expanded(child: Text(
                'NPK recomendado: ${selectedCropInfo.npk} — ${selectedCropInfo.npkNota}',
                style: const TextStyle(fontSize: 11, color: PeraCoColors.primaryDark),
              )),
            ]),
          ),
        ],

        const SizedBox(height: 12),

        // ── Fechas ──
        Row(children: [
          Expanded(child: _DateField(
            label: 'Siembra', value: _fechaSiembra != null ? _formatDate(_fechaSiembra!) : null,
            hint: 'Opcional', icon: Icons.grass, onTap: () => _pickDate(isCosecha: false),
          )),
          const SizedBox(width: 10),
          Expanded(child: _DateField(
            label: 'Cosecha estimada', value: _fechaCosecha != null ? _formatDate(_fechaCosecha!) : null,
            hint: 'Requerida', icon: Icons.agriculture_outlined, onTap: () => _pickDate(isCosecha: true),
          )),
        ]),
        const SizedBox(height: 12),

        // ── Cantidad + unidad ──
        Row(children: [
          Expanded(flex: 3, child: TextFormField(
            controller: _cantidadCtrl, keyboardType: TextInputType.number,
            style: PeraCoText.body(context),
            decoration: const InputDecoration(hintText: 'Cantidad estimada', prefixIcon: Icon(Icons.scale_outlined)),
          )),
          const SizedBox(width: 10),
          Expanded(flex: 2, child: DropdownButtonFormField<String>(
            value: _unidad,
            decoration: const InputDecoration(hintText: 'Unidad'),
            items: _unidades.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
            onChanged: (v) => setState(() => _unidad = v!),
          )),
        ]),
        const SizedBox(height: 12),

        // ── Sección agronómica (expandible) ──
        GestureDetector(
          onTap: () => setState(() => _showAgro = !_showAgro),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
                color: PeraCoColors.surfaceVariant, borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              const Icon(Icons.science_outlined, size: 18, color: PeraCoColors.primary),
              const SizedBox(width: 8),
              Expanded(child: Text('Datos agronómicos (opcional)',
                  style: PeraCoText.bodySmall(context).copyWith(color: PeraCoColors.primary, fontWeight: FontWeight.w600))),
              Icon(_showAgro ? Icons.expand_less : Icons.expand_more, color: PeraCoColors.primary),
            ]),
          ),
        ),

        if (_showAgro) ...[
          const SizedBox(height: 12),

          // Área cultivada
          TextFormField(
            controller: _areaCtrl, keyboardType: TextInputType.number,
            style: PeraCoText.body(context),
            decoration: const InputDecoration(
                hintText: 'Área cultivada (hectáreas)', prefixIcon: Icon(Icons.area_chart_outlined)),
          ),
          const SizedBox(height: 10),

          // Tipo de suelo
          DropdownButtonFormField<String>(
            value: _tipoSuelo,
            decoration: const InputDecoration(hintText: 'Tipo de suelo', prefixIcon: Icon(Icons.layers_outlined)),
            items: tiposSueloOptions.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (v) => setState(() => _tipoSuelo = v),
          ),
          const SizedBox(height: 10),

          // pH descriptivo
          DropdownButtonFormField<String>(
            value: _phDesc,
            decoration: const InputDecoration(hintText: 'pH del suelo', prefixIcon: Icon(Icons.water_drop_outlined)),
            items: const [
              DropdownMenuItem(value: 'Ácido', child: Text('Ácido (pH 4.5–5.5)')),
              DropdownMenuItem(value: 'Ligeramente ácido', child: Text('Ligeramente ácido (pH 5.5–6.5)')),
              DropdownMenuItem(value: 'Neutro', child: Text('Neutro (pH 6.5–7.5)')),
              DropdownMenuItem(value: 'Alcalino', child: Text('Alcalino (pH >7.5)')),
            ],
            onChanged: (v) => setState(() => _phDesc = v),
          ),
          const SizedBox(height: 10),

          // Fertilizante
          TextFormField(
            controller: _fertilizanteCtrl, style: PeraCoText.body(context),
            decoration: const InputDecoration(
                hintText: 'Fertilizante/abono a aplicar (NPK, abono orgánico...)',
                prefixIcon: Icon(Icons.biotech_outlined)),
          ),
        ],

        const SizedBox(height: 12),

        // ── Notas generales ──
        TextFormField(
          controller: _notasCtrl, maxLines: 2, style: PeraCoText.body(context),
          decoration: const InputDecoration(
              hintText: 'Notas (variedad, lote, observaciones...)', alignLabelWithHint: true),
        ),
        const SizedBox(height: 20),

        SizedBox(width: double.infinity, height: 52, child: ElevatedButton(
          onPressed: _loading ? null : _save,
          child: _loading
              ? const SizedBox(width: 22, height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
              : const Text('Registrar cosecha'),
        )),
      ]))),
    );
  }
}

// ──── Widgets auxiliares ────

class _DateField extends StatelessWidget {
  final String label;
  final String? value;
  final String hint;
  final IconData icon;
  final VoidCallback onTap;
  const _DateField({required this.label, this.value, required this.hint, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
              color: PeraCoColors.surfaceVariant, borderRadius: BorderRadius.circular(12),
              border: Border.all(color: value != null ? PeraCoColors.primary.withValues(alpha: 0.4) : PeraCoColors.divider)),
          child: Row(children: [
            Icon(icon, size: 18, color: value != null ? PeraCoColors.primary : PeraCoColors.textHint),
            const SizedBox(width: 8),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(fontSize: 9, color: PeraCoColors.textSecondary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(value ?? hint, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                  color: value != null ? PeraCoColors.textPrimary : PeraCoColors.textHint)),
            ])),
          ])),
    );
  }
}
