import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peraco/core/constants/colors.dart';
import 'package:peraco/core/constants/text_styles.dart';
import 'package:peraco/features/farmer/crops/data/crops_data.dart';
import 'package:peraco/features/farmer/crops/providers/cultivos_provider.dart';
import 'package:peraco/features/farmer/crops/widgets/harvest_form_sheet.dart';

// ──────────────────────────────────────────────────────────────────
// Modelo interno del perfil de finca
// ──────────────────────────────────────────────────────────────────
class _FarmProfile {
  String pais;
  double altitudM;
  String tempRango;   // 'Frío alto', 'Frío', 'Templado frío', 'Templado', 'Cálido'
  String precipRango; // 'Seco', 'Moderado', 'Húmedo', 'Muy húmedo'
  String tipoSuelo;
  String phDesc;      // 'Ácido', 'Ligeramente ácido', 'Neutro', 'Alcalino'
  String materiaOrganica; // 'Baja', 'Media', 'Alta'

  _FarmProfile({
    this.pais = 'Colombia',
    this.altitudM = 1500,
    this.tempRango = 'Templado frío',
    this.precipRango = 'Moderado',
    this.tipoSuelo = 'Franco',
    this.phDesc = 'Ligeramente ácido',
    this.materiaOrganica = 'Media',
  });

  double get tempPromedio {
    switch (tempRango) {
      case 'Frío alto': return 8;
      case 'Frío': return 12;
      case 'Templado frío': return 17;
      case 'Templado': return 22;
      case 'Cálido': return 27;
      default: return 22;
    }
  }

  int get precipAnual {
    switch (precipRango) {
      case 'Muy seco': return 400;
      case 'Seco': return 800;
      case 'Moderado': return 1300;
      case 'Húmedo': return 1800;
      case 'Muy húmedo': return 2600;
      default: return 1300;
    }
  }

  double get ph {
    switch (phDesc) {
      case 'Ácido': return 5.0;
      case 'Ligeramente ácido': return 6.0;
      case 'Neutro': return 7.0;
      case 'Alcalino': return 7.8;
      default: return 6.0;
    }
  }
}

class _CropScore {
  final CropInfo crop;
  final double score; // 0-100
  const _CropScore({required this.crop, required this.score});
}

// ──────────────────────────────────────────────────────────────────
// Sheet principal
// ──────────────────────────────────────────────────────────────────
class CropAdvisorSheet extends ConsumerStatefulWidget {
  const CropAdvisorSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CropAdvisorSheet(),
    );
  }

  @override
  ConsumerState<CropAdvisorSheet> createState() => _CropAdvisorSheetState();
}

class _CropAdvisorSheetState extends ConsumerState<CropAdvisorSheet> {
  final _profile = _FarmProfile();
  int _step = 0;
  List<_CropScore>? _results;

  static const _steps = ['Ubicación', 'Clima', 'Suelo', 'Resultados'];

  static const _tempOpciones = [
    ('Frío alto', '<12 °C', '❄️'),
    ('Frío', '12–16 °C', '🌬️'),
    ('Templado frío', '16–20 °C', '🌤️'),
    ('Templado', '20–25 °C', '☀️'),
    ('Cálido', '>25 °C', '🔆'),
  ];

  static const _precipOpciones = [
    ('Muy seco', '<600 mm', '🏜️'),
    ('Seco', '600–1.000 mm', '🌵'),
    ('Moderado', '1.000–1.500 mm', '🌦️'),
    ('Húmedo', '1.500–2.000 mm', '🌧️'),
    ('Muy húmedo', '>2.000 mm', '⛈️'),
  ];

  static const _phOpciones = [
    ('Ácido', 'pH 4.5–5.5', Colors.orange),
    ('Ligeramente ácido', 'pH 5.5–6.5', Colors.green),
    ('Neutro', 'pH 6.5–7.5', Colors.blue),
    ('Alcalino', 'pH >7.5', Colors.purple),
  ];

  // ──── Algoritmo de puntuación ────
  double _scoreCrop(CropInfo c) {
    double s = 0;
    final alt = _profile.altitudM.toInt();
    final temp = _profile.tempPromedio;
    final prec = _profile.precipAnual;
    final ph = _profile.ph;

    // Altitud (30 pts)
    if (alt >= c.altitudMinM && alt <= c.altitudMaxM) {
      s += 30;
    } else {
      final diff = alt < c.altitudMinM ? c.altitudMinM - alt : alt - c.altitudMaxM;
      if (diff <= 400) s += 15;
    }

    // Temperatura (25 pts)
    if (temp >= c.tempMinC && temp <= c.tempMaxC) {
      s += 25;
    } else {
      final diff = (temp < c.tempMinC ? c.tempMinC - temp : temp - c.tempMaxC);
      if (diff <= 4) s += 12;
    }

    // Precipitación (20 pts)
    if (prec >= c.precipMinMm && prec <= c.precipMaxMm) {
      s += 20;
    } else {
      final diff = prec < c.precipMinMm ? c.precipMinMm - prec : prec - c.precipMaxMm;
      if (diff <= 400) s += 10;
    }

    // Suelo (15 pts)
    if (c.tiposSuelo.contains(_profile.tipoSuelo)) s += 15;

    // pH (10 pts)
    if (ph >= c.phMin && ph <= c.phMax) {
      s += 10;
    } else {
      final diff = ph < c.phMin ? c.phMin - ph : ph - c.phMax;
      if (diff <= 0.8) s += 5;
    }

    return s;
  }

  void _calcular() {
    final crops = ref.read(cultivosProvider).valueOrNull ?? cropsData;
    final list = crops
        .map((c) => _CropScore(crop: c, score: _scoreCrop(c)))
        .where((s) => s.score >= 20)
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    setState(() { _results = list; _step = 3; });
  }

  // ──── Helpers de UI ────
  String _phAjuste(CropInfo c) {
    final ph = _profile.ph;
    if (ph >= c.phMin && ph <= c.phMax) return '✅ pH ideal para este cultivo';
    if (ph < c.phMin) return '⚠️ Encalar para subir pH a ${c.phMin}–${c.phMax}';
    return '⚠️ Acidificar para bajar pH a ${c.phMin}–${c.phMax}';
  }

  Color _scoreColor(double s) {
    if (s >= 80) return PeraCoColors.success;
    if (s >= 55) return PeraCoColors.primary;
    if (s >= 35) return PeraCoColors.warning;
    return PeraCoColors.error;
  }

  String _scoreLabel(double s) {
    if (s >= 80) return 'Excelente';
    if (s >= 55) return 'Buena';
    if (s >= 35) return 'Regular';
    return 'Baja';
  }

  // ──── Build ────
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92, maxChildSize: 0.97, minChildSize: 0.5,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(children: [
          // Handle
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(
              color: PeraCoColors.divider, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 12),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Container(width: 42, height: 42,
                  decoration: BoxDecoration(color: PeraCoColors.greenPastel, borderRadius: BorderRadius.circular(12)),
                  child: const Center(child: Text('🌱', style: TextStyle(fontSize: 22)))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Asesor Agrícola', style: PeraCoText.h3(context)),
                Text('Recomendaciones para tu finca', style: PeraCoText.caption(context).copyWith(color: PeraCoColors.textSecondary)),
              ])),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
            ]),
          ),

          // Step indicator
          if (_step < 3) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: List.generate(_steps.length - 1, (i) => Expanded(child: Row(children: [
                Container(width: 28, height: 28,
                    decoration: BoxDecoration(
                        color: i <= _step ? PeraCoColors.primary : PeraCoColors.surfaceVariant,
                        shape: BoxShape.circle),
                    child: Center(child: Text('${i + 1}',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                            color: i <= _step ? Colors.white : PeraCoColors.textHint)))),
                if (i < _steps.length - 2)
                  Expanded(child: Container(height: 2, color: i < _step ? PeraCoColors.primary : PeraCoColors.divider)),
              ])))),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(alignment: Alignment.centerLeft,
                  child: Text(_steps[_step], style: PeraCoText.bodyBold(context).copyWith(color: PeraCoColors.primary))),
            ),
          ],

          const Divider(height: 24),

          // Content
          Expanded(child: ListView(controller: ctrl, padding: const EdgeInsets.symmetric(horizontal: 20), children: [
            if (_step == 0) _buildStep0(),
            if (_step == 1) _buildStep1(),
            if (_step == 2) _buildStep2(),
            if (_step == 3) _buildResults(),
            const SizedBox(height: 20),
          ])),

          // Bottom navigation
          if (_step < 3)
            _buildNav(),
        ]),
      ),
    );
  }

  // ──── PASO 0: Ubicación ────
  Widget _buildStep0() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _Label('País / Región'),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(
        value: _profile.pais,
        decoration: const InputDecoration(prefixIcon: Icon(Icons.public)),
        items: latamPaises.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
        onChanged: (v) => setState(() => _profile.pais = v!),
      ),
      const SizedBox(height: 20),
      Row(children: [
        _Label('Altitud'),
        const Spacer(),
        Text('${_profile.altitudM.toInt()} msnm',
            style: PeraCoText.bodyBold(context).copyWith(color: PeraCoColors.primary)),
      ]),
      Slider(
        value: _profile.altitudM,
        min: 0, max: 4000,
        divisions: 80,
        activeColor: PeraCoColors.primary,
        label: '${_profile.altitudM.toInt()} m',
        onChanged: (v) => setState(() => _profile.altitudM = v),
      ),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('0 m (costa/llano)', style: PeraCoText.caption(context).copyWith(color: PeraCoColors.textHint)),
        Text('4.000 m (altiplano)', style: PeraCoText.caption(context).copyWith(color: PeraCoColors.textHint)),
      ]),
      const SizedBox(height: 16),
      _InfoBox('💡 La altitud determina la temperatura real y los cultivos adaptados a tu zona.'),
    ]);
  }

  // ──── PASO 1: Clima ────
  Widget _buildStep1() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _Label('Temperatura promedio del año'),
      const SizedBox(height: 10),
      Wrap(spacing: 8, runSpacing: 8, children: _tempOpciones.map((o) {
        final sel = _profile.tempRango == o.$1;
        return GestureDetector(
          onTap: () => setState(() => _profile.tempRango = o.$1),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
                color: sel ? PeraCoColors.primary.withValues(alpha: 0.1) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: sel ? PeraCoColors.primary : PeraCoColors.divider)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(o.$3, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(o.$1, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                    color: sel ? PeraCoColors.primary : PeraCoColors.textPrimary)),
                Text(o.$2, style: TextStyle(fontSize: 10, color: PeraCoColors.textSecondary)),
              ]),
            ]),
          ),
        );
      }).toList()),
      const SizedBox(height: 24),
      _Label('Lluvias anuales'),
      const SizedBox(height: 10),
      Column(children: _precipOpciones.map((o) {
        final sel = _profile.precipRango == o.$1;
        return GestureDetector(
          onTap: () => setState(() => _profile.precipRango = o.$1),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
                color: sel ? PeraCoColors.primary.withValues(alpha: 0.08) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: sel ? PeraCoColors.primary : PeraCoColors.divider)),
            child: Row(children: [
              Text(o.$3, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(o.$1, style: TextStyle(fontWeight: FontWeight.w600,
                    color: sel ? PeraCoColors.primary : PeraCoColors.textPrimary)),
                Text(o.$2, style: PeraCoText.caption(context).copyWith(color: PeraCoColors.textSecondary)),
              ])),
              if (sel) const Icon(Icons.check_circle, color: PeraCoColors.primary, size: 20),
            ]),
          ),
        );
      }).toList()),
    ]);
  }

  // ──── PASO 2: Suelo ────
  Widget _buildStep2() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _Label('Tipo de suelo'),
      const SizedBox(height: 10),
      Wrap(spacing: 8, runSpacing: 8, children: tiposSueloOptions.map((t) {
        final sel = _profile.tipoSuelo == t;
        return GestureDetector(
          onTap: () => setState(() => _profile.tipoSuelo = t),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
                color: sel ? PeraCoColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: sel ? PeraCoColors.primary : PeraCoColors.divider)),
            child: Text(t, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                color: sel ? Colors.white : PeraCoColors.textPrimary)),
          ),
        );
      }).toList()),
      const SizedBox(height: 20),
      _Label('pH del suelo'),
      const SizedBox(height: 10),
      Row(children: _phOpciones.map((o) => Expanded(child: GestureDetector(
        onTap: () => setState(() => _profile.phDesc = o.$1),
        child: Container(
          margin: const EdgeInsets.only(right: 6),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
              color: _profile.phDesc == o.$1 ? o.$3.withValues(alpha: 0.15) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _profile.phDesc == o.$1 ? o.$3 : PeraCoColors.divider)),
          child: Column(children: [
            Text(o.$1, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: o.$3),
                textAlign: TextAlign.center),
            Text(o.$2, style: const TextStyle(fontSize: 9, color: PeraCoColors.textSecondary),
                textAlign: TextAlign.center),
          ]),
        ),
      ))).toList()),
      const SizedBox(height: 20),
      _Label('Materia orgánica'),
      const SizedBox(height: 8),
      Row(children: ['Baja', 'Media', 'Alta'].map((mo) {
        final sel = _profile.materiaOrganica == mo;
        return Expanded(child: GestureDetector(
          onTap: () => setState(() => _profile.materiaOrganica = mo),
          child: Container(
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
                color: sel ? PeraCoColors.primary.withValues(alpha: 0.1) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: sel ? PeraCoColors.primary : PeraCoColors.divider)),
            child: Text(mo, textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13,
                    color: sel ? PeraCoColors.primary : PeraCoColors.textPrimary)),
          ),
        ));
      }).toList()),
      const SizedBox(height: 20),
      _InfoBox('💡 Si no tienes análisis de suelo, elige los valores típicos de tu zona y los consejos te indicarán cómo mejorar.'),
    ]);
  }

  // ──── PASO 3: Resultados ────
  Widget _buildResults() {
    final results = _results ?? [];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Resumen de condiciones
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: PeraCoColors.greenPastel, borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Condiciones de tu finca', style: PeraCoText.bodyBold(context).copyWith(color: PeraCoColors.primaryDark)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 4, children: [
            _Tag('📍 ${_profile.pais}'),
            _Tag('⛰️ ${_profile.altitudM.toInt()} msnm'),
            _Tag('🌡️ ${_profile.tempRango}'),
            _Tag('🌧️ ${_profile.precipRango}'),
            _Tag('🌱 ${_profile.tipoSuelo}'),
            _Tag('pH: ${_profile.phDesc}'),
            _Tag('MO: ${_profile.materiaOrganica}'),
          ]),
        ]),
      ),
      const SizedBox(height: 16),

      if (results.isEmpty) ...[
        const SizedBox(height: 40),
        Center(child: Column(children: [
          const Icon(Icons.search_off, size: 48, color: PeraCoColors.textHint),
          const SizedBox(height: 12),
          Text('Sin resultados', style: PeraCoText.bodyBold(context)),
          const SizedBox(height: 8),
          Text('Ajusta las condiciones e intenta de nuevo',
              style: PeraCoText.body(context).copyWith(color: PeraCoColors.textSecondary)),
          const SizedBox(height: 16),
          TextButton(onPressed: () => setState(() => _step = 0), child: const Text('Volver a ajustar')),
        ])),
      ] else ...[
        Row(children: [
          Text('${results.length} cultivos recomendados', style: PeraCoText.bodyBold(context)),
          const Spacer(),
          TextButton(onPressed: () => setState(() => _step = 0), child: const Text('Ajustar')),
        ]),
        const SizedBox(height: 8),
        ...results.map((s) => _ResultCard(score: s, phAjuste: _phAjuste(s.crop),
            scoreColor: _scoreColor(s.score), scoreLabel: _scoreLabel(s.score))),
      ],
    ]);
  }

  Widget _buildNav() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, -2))]),
      child: Row(children: [
        if (_step > 0)
          Expanded(child: OutlinedButton(
            onPressed: () => setState(() => _step--),
            child: const Text('Anterior'),
          )),
        if (_step > 0) const SizedBox(width: 12),
        Expanded(flex: 2, child: ElevatedButton(
          onPressed: _step < 2 ? () => setState(() => _step++) : _calcular,
          style: ElevatedButton.styleFrom(backgroundColor: PeraCoColors.primary, foregroundColor: Colors.white),
          child: Text(_step < 2 ? 'Siguiente' : 'Ver recomendaciones'),
        )),
      ]),
    );
  }
}

// ──────────────────────────────────────────────────────────────────
// Widgets auxiliares
// ──────────────────────────────────────────────────────────────────

class _ResultCard extends StatelessWidget {
  final _CropScore score;
  final String phAjuste;
  final Color scoreColor;
  final String scoreLabel;
  const _ResultCard({required this.score, required this.phAjuste, required this.scoreColor, required this.scoreLabel});

  @override
  Widget build(BuildContext context) {
    final c = score.crop;
    final pct = score.score.toInt();
    final inSeason = c.mesesSiembra.contains(DateTime.now().month);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: scoreColor.withValues(alpha: 0.3)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(c.emoji, style: const TextStyle(fontSize: 30)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(c.nombre, style: PeraCoText.bodyBold(context)),
            Text(c.clima, style: PeraCoText.caption(context).copyWith(color: PeraCoColors.textSecondary)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: scoreColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Text('$pct%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: scoreColor))),
            Text(scoreLabel, style: TextStyle(fontSize: 10, color: scoreColor, fontWeight: FontWeight.w600)),
          ]),
        ]),

        const SizedBox(height: 10),

        // Barra de compatibilidad
        ClipRRect(borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
                value: score.score / 100, minHeight: 6,
                backgroundColor: PeraCoColors.divider, color: scoreColor)),

        const SizedBox(height: 10),

        // Datos clave
        Wrap(spacing: 8, runSpacing: 6, children: [
          _InfoTag(icon: Icons.schedule, label: c.diasLabel),
          _InfoTag(icon: Icons.water_drop_outlined, label: c.precipLabel),
          _InfoTag(icon: Icons.thermostat, label: c.tempLabel),
          if (inSeason) _InfoTag(icon: Icons.eco, label: 'Temporada ahora', color: PeraCoColors.success),
        ]),

        const SizedBox(height: 10),

        // NPK
        Container(padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: PeraCoColors.greenPastel, borderRadius: BorderRadius.circular(8)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('🧪', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Fertilización N-P-K: ${c.npk}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: PeraCoColors.primaryDark)),
                const SizedBox(height: 2),
                Text(c.npkNota, style: const TextStyle(fontSize: 11, color: PeraCoColors.textSecondary)),
              ])),
            ])),

        const SizedBox(height: 8),

        // pH ajuste
        Row(children: [
          const SizedBox(width: 2),
          Expanded(child: Text(phAjuste, style: const TextStyle(fontSize: 11, color: PeraCoColors.textSecondary))),
        ]),

        const SizedBox(height: 12),

        SizedBox(width: double.infinity, height: 40,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                HarvestFormSheet.show(context, preselectedCrop: c.nombre);
              },
              icon: const Icon(Icons.add_circle_outline, size: 16),
              label: Text('Planificar cosecha de ${c.nombre}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: PeraCoColors.primary, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            )),
      ]),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) =>
      Text(text, style: PeraCoText.bodyBold(context));
}

class _Tag extends StatelessWidget {
  final String text;
  const _Tag(this.text);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8),
          border: Border.all(color: PeraCoColors.primary.withValues(alpha: 0.3))),
      child: Text(text, style: const TextStyle(fontSize: 11, color: PeraCoColors.primaryDark, fontWeight: FontWeight.w500)),
    );
  }
}

class _InfoTag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoTag({required this.icon, required this.label, this.color = PeraCoColors.textSecondary});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: PeraCoColors.surfaceVariant, borderRadius: BorderRadius.circular(6)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String text;
  const _InfoBox(this.text);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: PeraCoColors.info.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10), border: Border.all(color: PeraCoColors.info.withValues(alpha: 0.2))),
      child: Text(text, style: TextStyle(fontSize: 12, color: PeraCoColors.info, height: 1.4)),
    );
  }
}
