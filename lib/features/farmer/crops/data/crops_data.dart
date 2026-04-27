import 'package:flutter/material.dart';

Color _hexToColor(String hex) {
  final clean = hex.replaceFirst('#', '');
  return Color(int.parse('FF$clean', radix: 16));
}

const List<String> latamPaises = [
  'México', 'Guatemala', 'Honduras', 'El Salvador', 'Nicaragua',
  'Costa Rica', 'Panamá', 'Colombia', 'Venezuela', 'Ecuador',
  'Perú', 'Bolivia', 'Chile', 'Argentina', 'Uruguay', 'Paraguay',
  'Brasil', 'Rep. Dominicana',
];

const List<String> tiposSueloOptions = [
  'Franco', 'Franco-arenoso', 'Franco-arcilloso',
  'Arcilloso', 'Arenoso', 'Franco-limoso',
];

class CropInfo {
  final String id;
  final String nombre;
  final String emoji;
  final String clima;
  final String altitud;
  final List<int> mesesSiembra;
  final List<int> mesesCosecha;
  final int diasCosechaMin;
  final int diasCosechaMax;
  final String agua;
  final String suelo;
  final List<String> consejos;
  final Color color;

  // Campos para el asesor
  final int altitudMinM;
  final int altitudMaxM;
  final double tempMinC;
  final double tempMaxC;
  final int precipMinMm;
  final int precipMaxMm;
  final List<String> tiposSuelo;
  final double phMin;
  final double phMax;
  final String npk;       // ratio N-P-K recomendado
  final String npkNota;   // instrucción breve de fertilización
  final List<String> paises;

  const CropInfo({
    required this.id,
    required this.nombre,
    required this.emoji,
    required this.clima,
    required this.altitud,
    required this.mesesSiembra,
    required this.mesesCosecha,
    required this.diasCosechaMin,
    required this.diasCosechaMax,
    required this.agua,
    required this.suelo,
    required this.consejos,
    required this.color,
    required this.altitudMinM,
    required this.altitudMaxM,
    required this.tempMinC,
    required this.tempMaxC,
    required this.precipMinMm,
    required this.precipMaxMm,
    required this.tiposSuelo,
    required this.phMin,
    required this.phMax,
    required this.npk,
    required this.npkNota,
    required this.paises,
  });

  String get siembraLabel {
    const meses = ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
    if (mesesSiembra.length == 12) return 'Todo el año';
    return mesesSiembra.map((m) => meses[m - 1]).join(', ');
  }

  String get cosechaLabel {
    const meses = ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
    if (mesesCosecha.length == 12) return 'Todo el año';
    return mesesCosecha.map((m) => meses[m - 1]).join(', ');
  }

  String get diasLabel => '$diasCosechaMin – $diasCosechaMax días';

  String get altitudLabel => '$altitudMinM – $altitudMaxM msnm';
  String get tempLabel => '${tempMinC.toInt()} – ${tempMaxC.toInt()} °C';
  String get precipLabel => '$precipMinMm – $precipMaxMm mm/año';

  factory CropInfo.fromMap(Map<String, dynamic> m) {
    List<int> _intList(dynamic v) =>
        v == null ? [] : (v as List).map((e) => (e as num).toInt()).toList();
    List<String> _strList(dynamic v) =>
        v == null ? [] : (v as List).map((e) => e as String).toList();

    return CropInfo(
      id: m['id'] as String,
      nombre: m['nombre'] as String,
      emoji: m['emoji'] as String? ?? '🌱',
      clima: m['clima'] as String? ?? '',
      altitud: m['altitud'] as String? ?? '',
      mesesSiembra: _intList(m['meses_siembra']),
      mesesCosecha: _intList(m['meses_cosecha']),
      diasCosechaMin: (m['dias_cosecha_min'] as num).toInt(),
      diasCosechaMax: (m['dias_cosecha_max'] as num).toInt(),
      agua: m['agua'] as String? ?? '',
      suelo: m['suelo'] as String? ?? '',
      consejos: _strList(m['consejos']),
      color: _hexToColor(m['color'] as String? ?? '#9CC200'),
      altitudMinM: (m['altitud_min_m'] as num).toInt(),
      altitudMaxM: (m['altitud_max_m'] as num).toInt(),
      tempMinC: (m['temp_min_c'] as num).toDouble(),
      tempMaxC: (m['temp_max_c'] as num).toDouble(),
      precipMinMm: (m['precip_min_mm'] as num).toInt(),
      precipMaxMm: (m['precip_max_mm'] as num).toInt(),
      tiposSuelo: _strList(m['tipos_suelo']),
      phMin: (m['ph_min'] as num).toDouble(),
      phMax: (m['ph_max'] as num).toDouble(),
      npk: m['npk'] as String? ?? '',
      npkNota: m['npk_nota'] as String? ?? '',
      paises: _strList(m['paises']),
    );
  }
}

const List<CropInfo> cropsData = [

  // ─────────────── CULTIVOS ANDINOS / COLOMBIA ───────────────

  CropInfo(
    id: 'papa', nombre: 'Papa', emoji: '🥔',
    clima: 'Frío (6–14 °C)', altitud: '2.000 – 3.200 msnm',
    mesesSiembra: [2, 3, 4, 8, 9, 10],
    mesesCosecha: [5, 6, 7, 11, 12, 1],
    diasCosechaMin: 90, diasCosechaMax: 120,
    agua: 'Moderado (500–700 mm/ciclo)',
    suelo: 'Franco, bien drenado, pH 5.0–6.5',
    color: Color(0xFF8D6E63),
    altitudMinM: 2000, altitudMaxM: 3200,
    tempMinC: 6, tempMaxC: 14,
    precipMinMm: 500, precipMaxMm: 800,
    tiposSuelo: ['Franco', 'Franco-arenoso'],
    phMin: 5.0, phMax: 6.5,
    npk: '10-20-10',
    npkNota: 'Fósforo en siembra; N fraccionado al aporque y 30 días después',
    paises: ['Colombia', 'Perú', 'Bolivia', 'Ecuador', 'Chile', 'Argentina', 'México'],
    consejos: [
      'Rotar cultivo cada 2–3 años para evitar enfermedades del suelo.',
      'Aplicar fungicidas preventivos contra gota (Phytophthora infestans).',
      'Aporcar las plantas a los 30 días para estimular la tuberización.',
      'Cosechar en días secos; dejar curar 1 semana antes de almacenar.',
    ],
  ),

  CropInfo(
    id: 'fresa', nombre: 'Fresa', emoji: '🍓',
    clima: 'Frío moderado (14–20 °C)', altitud: '1.500 – 2.200 msnm',
    mesesSiembra: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
    mesesCosecha: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
    diasCosechaMin: 60, diasCosechaMax: 90,
    agua: 'Frecuente (riego por goteo ideal)',
    suelo: 'Franco-arenoso, bien drenado, pH 5.5–6.5',
    color: Color(0xFFE53935),
    altitudMinM: 1500, altitudMaxM: 2200,
    tempMinC: 14, tempMaxC: 20,
    precipMinMm: 800, precipMaxMm: 1200,
    tiposSuelo: ['Franco-arenoso', 'Franco'],
    phMin: 5.5, phMax: 6.5,
    npk: '20-15-15',
    npkNota: 'Fertiriego continuo; aumentar K a 20 en fructificación',
    paises: ['Colombia', 'México', 'Chile', 'Perú', 'Argentina'],
    consejos: [
      'Plantar en camas elevadas (30 cm) para mejorar drenaje y aireación.',
      'Usar acolchado plástico negro para controlar malezas y conservar humedad.',
      'Cosechar cada 2–3 días en temporada alta.',
      'Renovar plantas cada 2–3 años para mantener productividad.',
    ],
  ),

  CropInfo(
    id: 'tomate', nombre: 'Tomate', emoji: '🍅',
    clima: 'Cálido-templado (18–26 °C)', altitud: '0 – 2.000 msnm',
    mesesSiembra: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
    mesesCosecha: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
    diasCosechaMin: 70, diasCosechaMax: 90,
    agua: 'Regular (evitar encharcamiento)',
    suelo: 'Franco, rico en materia orgánica, pH 5.5–6.8',
    color: Color(0xFFEF6C00),
    altitudMinM: 0, altitudMaxM: 2000,
    tempMinC: 18, tempMaxC: 26,
    precipMinMm: 600, precipMaxMm: 1500,
    tiposSuelo: ['Franco', 'Franco-arcilloso'],
    phMin: 5.5, phMax: 6.8,
    npk: '12-6-20',
    npkNota: 'Alto K en floración; evitar exceso de N para no favorecer follaje sobre fruto',
    paises: ['México', 'Colombia', 'Perú', 'Chile', 'Argentina', 'Brasil', 'Bolivia', 'Ecuador', 'Guatemala'],
    consejos: [
      'Tutorear las plantas a los 20 cm de altura con estacas o espalderas.',
      'Podar chupones laterales semanalmente para concentrar producción.',
      'Vigilar mosca blanca y ácaros; aplicar neem oil preventivo.',
      'Cosechar antes de lluvias fuertes para evitar rajaduras.',
    ],
  ),

  CropInfo(
    id: 'arveja', nombre: 'Arveja', emoji: '🫛',
    clima: 'Frío (10–18 °C)', altitud: '2.000 – 3.000 msnm',
    mesesSiembra: [2, 3, 8, 9],
    mesesCosecha: [5, 6, 11, 12],
    diasCosechaMin: 90, diasCosechaMax: 120,
    agua: 'Moderado (evitar exceso)',
    suelo: 'Franco-limoso, bien drenado, pH 6.0–7.0',
    color: Color(0xFF388E3C),
    altitudMinM: 2000, altitudMaxM: 3000,
    tempMinC: 10, tempMaxC: 18,
    precipMinMm: 500, precipMaxMm: 900,
    tiposSuelo: ['Franco-limoso', 'Franco'],
    phMin: 6.0, phMax: 7.0,
    npk: '5-20-10',
    npkNota: 'Leguminosa: inocular semilla con Rhizobium; reducir nitrógeno al mínimo',
    paises: ['Colombia', 'Ecuador', 'Perú', 'Bolivia', 'Chile', 'Argentina'],
    consejos: [
      'Inocular semilla con Rhizobium para fijar nitrógeno y reducir fertilizante.',
      'Usar mallas o estacas desde el inicio para sostener el guía.',
      'Cosechar en verde (vaina turgente) para consumo fresco.',
      'Para semilla seca, esperar hasta que la vaina se torne amarilla.',
    ],
  ),

  CropInfo(
    id: 'zanahoria', nombre: 'Zanahoria', emoji: '🥕',
    clima: 'Frío (14–20 °C)', altitud: '1.800 – 2.800 msnm',
    mesesSiembra: [2, 3, 4, 8, 9, 10],
    mesesCosecha: [5, 6, 7, 11, 12, 1],
    diasCosechaMin: 90, diasCosechaMax: 120,
    agua: 'Regular y uniforme',
    suelo: 'Franco-arenoso, profundo y suelto, pH 6.0–6.8',
    color: Color(0xFFFF8F00),
    altitudMinM: 1800, altitudMaxM: 2800,
    tempMinC: 14, tempMaxC: 20,
    precipMinMm: 600, precipMaxMm: 900,
    tiposSuelo: ['Franco-arenoso', 'Franco-limoso'],
    phMin: 6.0, phMax: 6.8,
    npk: '10-15-10',
    npkNota: 'Evitar abono orgánico fresco (deforma raíces); K para engorde de raíz',
    paises: ['Colombia', 'México', 'Perú', 'Chile', 'Argentina', 'Ecuador', 'Bolivia'],
    consejos: [
      'Desmenuzar el suelo a 30 cm de profundidad; piedras deforman la raíz.',
      'Sembrar en hileras a 5 cm entre plantas; ralear a los 15 días.',
      'Evitar abonos orgánicos frescos (causan bifurcación de raíces).',
      'Cosechar cuando el hombro verde sea visible en la superficie.',
    ],
  ),

  CropInfo(
    id: 'cebolla', nombre: 'Cebolla larga', emoji: '🧅',
    clima: 'Frío-templado (12–22 °C)', altitud: '1.800 – 2.800 msnm',
    mesesSiembra: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
    mesesCosecha: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
    diasCosechaMin: 120, diasCosechaMax: 150,
    agua: 'Regular (goteo o aspersión)',
    suelo: 'Franco, suelto, bien drenado, pH 6.0–7.0',
    color: Color(0xFF7B1FA2),
    altitudMinM: 1800, altitudMaxM: 2800,
    tempMinC: 12, tempMaxC: 22,
    precipMinMm: 600, precipMaxMm: 1000,
    tiposSuelo: ['Franco', 'Franco-limoso'],
    phMin: 6.0, phMax: 7.0,
    npk: '10-10-15',
    npkNota: 'K para engrosamiento del tallo; aplicar en 3 fracciones durante el ciclo',
    paises: ['Colombia', 'Ecuador', 'México', 'Perú', 'Venezuela'],
    consejos: [
      'Usar hijuelos de buena calidad, desinfectados antes de siembra.',
      'Fertilizar con alto contenido de potasio para engrosar el tallo.',
      'Aporcar a los 30 días para blanquear el tallo y mejorar calidad.',
      'Cosechar cuando el 50% de las plantas tengan el follaje doblado.',
    ],
  ),

  CropInfo(
    id: 'lechuga', nombre: 'Lechuga', emoji: '🥬',
    clima: 'Frío-templado (15–20 °C)', altitud: '1.500 – 2.500 msnm',
    mesesSiembra: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
    mesesCosecha: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
    diasCosechaMin: 45, diasCosechaMax: 60,
    agua: 'Frecuente y ligero',
    suelo: 'Franco, rico en materia orgánica, pH 6.0–7.0',
    color: Color(0xFF558B2F),
    altitudMinM: 1500, altitudMaxM: 2500,
    tempMinC: 15, tempMaxC: 20,
    precipMinMm: 400, precipMaxMm: 800,
    tiposSuelo: ['Franco', 'Franco-limoso'],
    phMin: 6.0, phMax: 7.0,
    npk: '20-10-10',
    npkNota: 'Alto N para formación rápida de hojas; riego frecuente y liviano',
    paises: ['Colombia', 'México', 'Chile', 'Argentina', 'Perú', 'Ecuador', 'Bolivia', 'Brasil'],
    consejos: [
      'Transplantar plántulas de 20–25 días de almácigo.',
      'Evitar encharcamiento; causa pudrición de cuello.',
      'Cosechar en la mañana para mayor frescura y vida útil.',
      'Escalonar siembras cada 15 días para producción continua.',
    ],
  ),

  CropInfo(
    id: 'maiz', nombre: 'Maíz', emoji: '🌽',
    clima: 'Cálido-templado (20–30 °C)', altitud: '0 – 1.800 msnm',
    mesesSiembra: [3, 4, 5, 9, 10],
    mesesCosecha: [6, 7, 8, 12, 1],
    diasCosechaMin: 90, diasCosechaMax: 120,
    agua: 'Moderado-alto en floración',
    suelo: 'Franco, profundo, bien drenado, pH 5.5–7.0',
    color: Color(0xFFF9A825),
    altitudMinM: 0, altitudMaxM: 1800,
    tempMinC: 20, tempMaxC: 30,
    precipMinMm: 500, precipMaxMm: 1200,
    tiposSuelo: ['Franco', 'Franco-arcilloso'],
    phMin: 5.5, phMax: 7.0,
    npk: '15-10-10',
    npkNota: 'N fraccionado: 30% en siembra, 70% en V6; crítico en floración',
    paises: ['México', 'Colombia', 'Perú', 'Bolivia', 'Brasil', 'Argentina', 'Ecuador', 'Guatemala', 'Honduras', 'El Salvador', 'Nicaragua'],
    consejos: [
      'Densidad de siembra: 50.000–60.000 plantas/ha en surcos a 80 cm.',
      'Aplicar nitrógeno fraccionado: 30% siembra, 70% en V6.',
      'Controlar gusano cogollero (Spodoptera) desde germinación.',
      'Maíz tierno: cosechar 20 días después de la floración femenina.',
    ],
  ),

  CropInfo(
    id: 'mora', nombre: 'Mora de Castilla', emoji: '🫐',
    clima: 'Frío moderado (12–18 °C)', altitud: '1.500 – 2.400 msnm',
    mesesSiembra: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
    mesesCosecha: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
    diasCosechaMin: 180, diasCosechaMax: 240,
    agua: 'Moderado y uniforme',
    suelo: 'Franco-arcilloso, bien drenado, pH 5.5–6.5',
    color: Color(0xFF6A1B9A),
    altitudMinM: 1500, altitudMaxM: 2400,
    tempMinC: 12, tempMaxC: 18,
    precipMinMm: 1000, precipMaxMm: 2000,
    tiposSuelo: ['Franco-arcilloso', 'Franco'],
    phMin: 5.5, phMax: 6.5,
    npk: '15-15-15',
    npkNota: 'Fertilización balanceada 3 veces/año; incorporar materia orgánica anualmente',
    paises: ['Colombia', 'Ecuador', 'México', 'Perú'],
    consejos: [
      'Instalar tutores en espaldera (2 alambres a 0.8 y 1.4 m de altura).',
      'Podar ramas cosechadas; dejar 3–4 ramas nuevas por planta.',
      'Cosechar en estado pintón-maduro para mejor precio en mercado.',
      'Producción continua después de 8–10 meses; vida útil 8–10 años.',
    ],
  ),

  CropInfo(
    id: 'aguacate', nombre: 'Aguacate', emoji: '🥑',
    clima: 'Templado (15–25 °C)', altitud: '1.000 – 2.000 msnm',
    mesesSiembra: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
    mesesCosecha: [3, 4, 5, 9, 10, 11],
    diasCosechaMin: 365, diasCosechaMax: 548,
    agua: 'Moderado (sensible a encharcamiento)',
    suelo: 'Franco, profundo, bien drenado, pH 5.5–7.0',
    color: Color(0xFF2E7D32),
    altitudMinM: 1000, altitudMaxM: 2000,
    tempMinC: 15, tempMaxC: 25,
    precipMinMm: 1200, precipMaxMm: 1800,
    tiposSuelo: ['Franco', 'Franco-arenoso'],
    phMin: 5.5, phMax: 7.0,
    npk: '10-5-15',
    npkNota: 'K para calidad del fruto; evitar encharcamiento que causa Phytophthora',
    paises: ['México', 'Colombia', 'Perú', 'Chile', 'Rep. Dominicana', 'Guatemala', 'Brasil', 'Ecuador', 'Bolivia'],
    consejos: [
      'Injerto sobre patrón tolerante a Phytophthora para mayor vigor.',
      'Poda de formación los primeros 2 años; luego solo sanitaria.',
      'Determinar cosecha por porcentaje de aceite (mínimo 8–11%).',
      'Un árbol adulto puede producir 200–400 frutos por cosecha.',
    ],
  ),

  CropInfo(
    id: 'cafe', nombre: 'Café', emoji: '☕',
    clima: 'Templado (17–23 °C)', altitud: '1.200 – 1.800 msnm',
    mesesSiembra: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
    mesesCosecha: [9, 10, 11, 12, 1, 2],
    diasCosechaMin: 180, diasCosechaMax: 270,
    agua: 'Bien distribuido (1.800–2.800 mm/año)',
    suelo: 'Franco-arcilloso, rico en materia orgánica, pH 5.0–6.5',
    color: Color(0xFF5D4037),
    altitudMinM: 1200, altitudMaxM: 1800,
    tempMinC: 17, tempMaxC: 23,
    precipMinMm: 1800, precipMaxMm: 2800,
    tiposSuelo: ['Franco-arcilloso', 'Franco'],
    phMin: 5.0, phMax: 6.5,
    npk: '10-5-10',
    npkNota: 'Dividir en 4 aplicaciones/año; Ca y Mg esenciales para calidad de taza',
    paises: ['Colombia', 'Brasil', 'México', 'Guatemala', 'Honduras', 'Ecuador', 'Perú', 'Bolivia', 'Costa Rica', 'Nicaragua', 'El Salvador'],
    consejos: [
      'Variedad Colombia o Castillo son resistentes a roya.',
      'Cosechar solo granos maduros (rojo-cereza) para mejor calidad.',
      'Despulpar en las primeras 8 horas post-cosecha.',
      'Renovar plantación cada 7–10 años mediante zoca.',
    ],
  ),

  CropInfo(
    id: 'platano', nombre: 'Plátano', emoji: '🍌',
    clima: 'Cálido (20–30 °C)', altitud: '0 – 1.200 msnm',
    mesesSiembra: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
    mesesCosecha: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
    diasCosechaMin: 270, diasCosechaMax: 365,
    agua: 'Alto (1.800–2.500 mm/año)',
    suelo: 'Franco, profundo, bien drenado, pH 5.5–7.0',
    color: Color(0xFFF57F17),
    altitudMinM: 0, altitudMaxM: 1200,
    tempMinC: 20, tempMaxC: 30,
    precipMinMm: 1800, precipMaxMm: 2500,
    tiposSuelo: ['Franco', 'Franco-arcilloso'],
    phMin: 5.5, phMax: 7.0,
    npk: '10-5-20',
    npkNota: 'Alto K para calibre del fruto; aplicar después de deshija',
    paises: ['Colombia', 'Ecuador', 'México', 'Guatemala', 'Honduras', 'Costa Rica', 'Rep. Dominicana', 'Brasil', 'Bolivia', 'Perú', 'Venezuela'],
    consejos: [
      'Deshijar dejando un hijo de espada por planta para continuidad.',
      'Defoliar hojas secas y desflorecer el pinzón para mayor calibre.',
      'Cosechar con 75% de llenado (ángulos redondeados en los dedos).',
      'Empacar en hojas para proteger en transporte y mejorar precio.',
    ],
  ),

  // ─────────────── CULTIVOS LATAM ───────────────

  CropInfo(
    id: 'quinua', nombre: 'Quinua', emoji: '🌾',
    clima: 'Frío andino (5–15 °C)', altitud: '2.500 – 4.000 msnm',
    mesesSiembra: [9, 10, 11],
    mesesCosecha: [3, 4, 5],
    diasCosechaMin: 150, diasCosechaMax: 180,
    agua: 'Bajo-moderado (300–700 mm/año)',
    suelo: 'Franco-arenoso, bien drenado, pH 6.0–7.5',
    color: Color(0xFFD4A017),
    altitudMinM: 2500, altitudMaxM: 4000,
    tempMinC: 5, tempMaxC: 15,
    precipMinMm: 300, precipMaxMm: 700,
    tiposSuelo: ['Franco-arenoso', 'Franco'],
    phMin: 6.0, phMax: 7.5,
    npk: '5-10-5',
    npkNota: 'Bajo requerimiento; exceso de N reduce proteína del grano; tolera salinidad',
    paises: ['Perú', 'Bolivia', 'Ecuador', 'Colombia', 'Chile', 'Argentina'],
    consejos: [
      'Resistente a heladas hasta -4°C en etapa vegetativa.',
      'Lavar el grano antes de cosechar para eliminar saponinas.',
      'Densidad de siembra: 10–15 kg/ha de semilla en surcos.',
      'Rotar con papa o habas para romper ciclos de plagas.',
    ],
  ),

  CropInfo(
    id: 'yuca', nombre: 'Yuca / Mandioca', emoji: '🌿',
    clima: 'Cálido (20–30 °C)', altitud: '0 – 1.800 msnm',
    mesesSiembra: [1, 2, 3, 4, 5, 9, 10, 11],
    mesesCosecha: [7, 8, 9, 10, 11, 12, 1, 2],
    diasCosechaMin: 180, diasCosechaMax: 365,
    agua: 'Tolerante a sequía (600–2.000 mm/año)',
    suelo: 'Franco-arenoso, profundo, pH 5.0–7.0',
    color: Color(0xFF795548),
    altitudMinM: 0, altitudMaxM: 1800,
    tempMinC: 20, tempMaxC: 30,
    precipMinMm: 600, precipMaxMm: 2000,
    tiposSuelo: ['Franco-arenoso', 'Franco'],
    phMin: 5.0, phMax: 7.0,
    npk: '5-10-15',
    npkNota: 'Tolera suelos pobres; K mejora calidad y rendimiento de raíces',
    paises: ['Brasil', 'Colombia', 'Ecuador', 'Perú', 'Bolivia', 'México', 'Venezuela', 'Guatemala', 'Paraguay'],
    consejos: [
      'Usar estacas sanas de 20–25 cm tomadas del tercio medio del tallo.',
      'Sembrar en posición horizontal o inclinada a 45° en suelo suelto.',
      'Cosechar entre 8–18 meses según variedad; raíces muy harinosas a los 12 meses.',
      'Excelente cultivo de seguridad alimentaria en zonas secas.',
    ],
  ),

  CropInfo(
    id: 'camote', nombre: 'Camote / Boniato', emoji: '🍠',
    clima: 'Cálido-templado (18–28 °C)', altitud: '0 – 2.500 msnm',
    mesesSiembra: [1, 2, 3, 4, 9, 10, 11],
    mesesCosecha: [4, 5, 6, 7, 12, 1, 2],
    diasCosechaMin: 90, diasCosechaMax: 150,
    agua: 'Moderado (500–1.500 mm/año)',
    suelo: 'Franco-arenoso, suelto y profundo, pH 5.5–6.8',
    color: Color(0xFFE65100),
    altitudMinM: 0, altitudMaxM: 2500,
    tempMinC: 18, tempMaxC: 28,
    precipMinMm: 500, precipMaxMm: 1500,
    tiposSuelo: ['Franco-arenoso', 'Franco'],
    phMin: 5.5, phMax: 6.8,
    npk: '10-15-20',
    npkNota: 'Alto K para engrosamiento de raíz; exceso de N favorece follaje sobre tubérculo',
    paises: ['Perú', 'Bolivia', 'México', 'Brasil', 'Ecuador', 'Argentina', 'Colombia', 'Venezuela'],
    consejos: [
      'Usar esquejes o bejucos de 30–40 cm de largo como material de siembra.',
      'Sembrar en camellones de 30 cm de alto para mejor drenaje.',
      'Alta tolerancia a sequía una vez establecido (primeros 30 días críticos).',
      'Cosechar antes de lluvias excesivas para evitar pudrición de raíces.',
    ],
  ),

  CropInfo(
    id: 'mango', nombre: 'Mango', emoji: '🥭',
    clima: 'Cálido (22–32 °C)', altitud: '0 – 1.000 msnm',
    mesesSiembra: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
    mesesCosecha: [11, 12, 1, 2, 3, 4, 5],
    diasCosechaMin: 100, diasCosechaMax: 150,
    agua: 'Moderado, sequia antes de floración (750–2.000 mm/año)',
    suelo: 'Franco, profundo, bien drenado, pH 5.5–7.5',
    color: Color(0xFFFF6F00),
    altitudMinM: 0, altitudMaxM: 1000,
    tempMinC: 22, tempMaxC: 32,
    precipMinMm: 750, precipMaxMm: 2000,
    tiposSuelo: ['Franco', 'Franco-arenoso'],
    phMin: 5.5, phMax: 7.5,
    npk: '10-5-15',
    npkNota: 'K en poscosecha para recuperación; evitar N excesivo en árboles adultos',
    paises: ['México', 'Brasil', 'Perú', 'Colombia', 'Ecuador', 'Rep. Dominicana', 'Venezuela', 'Bolivia', 'Guatemala'],
    consejos: [
      'La sequía moderada antes de floración induce mayor producción.',
      'Injertar sobre patrón local para adaptación y precocidad.',
      'Distancia de siembra: 8×8 m o 10×10 m según variedad.',
      'Controlar antracnosis con fungicidas cúpricos en pre-floración.',
    ],
  ),

  CropInfo(
    id: 'cacao', nombre: 'Cacao', emoji: '🫘',
    clima: 'Cálido húmedo (22–32 °C)', altitud: '0 – 900 msnm',
    mesesSiembra: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
    mesesCosecha: [10, 11, 12, 1, 2, 3],
    diasCosechaMin: 180, diasCosechaMax: 270,
    agua: 'Alto (1.500–2.500 mm/año)',
    suelo: 'Franco-arcilloso, rico en materia orgánica, pH 5.5–7.0',
    color: Color(0xFF4E342E),
    altitudMinM: 0, altitudMaxM: 900,
    tempMinC: 22, tempMaxC: 32,
    precipMinMm: 1500, precipMaxMm: 2500,
    tiposSuelo: ['Franco-arcilloso', 'Franco'],
    phMin: 5.5, phMax: 7.0,
    npk: '10-5-10',
    npkNota: 'K+Mg para calidad del grano; incorporar compost anualmente',
    paises: ['Brasil', 'Colombia', 'Ecuador', 'Perú', 'México', 'Rep. Dominicana', 'Venezuela', 'Bolivia', 'Guatemala'],
    consejos: [
      'Requiere sombra en los primeros 2 años (plátano o guamo como sombra temporal).',
      'Poda fitosanitaria cada 3–4 meses para controlar moniliasis.',
      'Fermentar y secar correctamente para certificar calidad de exportación.',
      'Variedades CCN-51 o ICS-95 para mayor resistencia y productividad.',
    ],
  ),

  CropInfo(
    id: 'papaya', nombre: 'Papaya', emoji: '🍈',
    clima: 'Cálido (22–32 °C)', altitud: '0 – 1.000 msnm',
    mesesSiembra: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
    mesesCosecha: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
    diasCosechaMin: 180, diasCosechaMax: 240,
    agua: 'Moderado-alto (1.000–2.000 mm/año)',
    suelo: 'Franco, bien drenado, pH 5.5–7.0',
    color: Color(0xFFFF7043),
    altitudMinM: 0, altitudMaxM: 1000,
    tempMinC: 22, tempMaxC: 32,
    precipMinMm: 1000, precipMaxMm: 2000,
    tiposSuelo: ['Franco', 'Franco-arenoso'],
    phMin: 5.5, phMax: 7.0,
    npk: '15-5-15',
    npkNota: 'N+K balanceados para crecimiento rápido; sensible a encharcamiento',
    paises: ['México', 'Brasil', 'Colombia', 'Ecuador', 'Bolivia', 'Perú', 'Rep. Dominicana'],
    consejos: [
      'Plantar 3 semillas por hoyo para luego seleccionar planta bisexual.',
      'Sensible a encharcamiento; hacer surcos de drenaje en zonas lluviosas.',
      'Producción comienza a los 6–8 meses; ciclo útil de 2–3 años.',
      'Controlar virus del mosaico con control de áfidos desde semillero.',
    ],
  ),

  CropInfo(
    id: 'pina', nombre: 'Piña', emoji: '🍍',
    clima: 'Cálido (18–28 °C)', altitud: '0 – 1.500 msnm',
    mesesSiembra: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
    mesesCosecha: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
    diasCosechaMin: 360, diasCosechaMax: 540,
    agua: 'Moderado, tolera periodos secos (1.000–2.000 mm/año)',
    suelo: 'Franco-arenoso, muy bien drenado, pH 4.5–6.0',
    color: Color(0xFFFFCA28),
    altitudMinM: 0, altitudMaxM: 1500,
    tempMinC: 18, tempMaxC: 28,
    precipMinMm: 1000, precipMaxMm: 2000,
    tiposSuelo: ['Franco-arenoso', 'Franco'],
    phMin: 4.5, phMax: 6.0,
    npk: '10-5-20',
    npkNota: 'K para dulzura y peso del fruto; aplicar N en etapas vegetativas',
    paises: ['Brasil', 'México', 'Colombia', 'Costa Rica', 'Ecuador', 'Venezuela', 'Rep. Dominicana'],
    consejos: [
      'Usar coronas o hijuelos como material de siembra; tratar con fungicida.',
      'Inducir floración con etileno (carburo) al mes 12 para uniformidad.',
      'Distancia de siembra: 30×60 cm en doble hilera.',
      'Cosechar cuando la cáscara cambie de verde oscuro a verde-amarillo.',
    ],
  ),

  CropInfo(
    id: 'chile', nombre: 'Chile / Ají', emoji: '🌶️',
    clima: 'Cálido-templado (18–30 °C)', altitud: '0 – 2.000 msnm',
    mesesSiembra: [1, 2, 3, 4, 5, 9, 10, 11],
    mesesCosecha: [4, 5, 6, 7, 12, 1, 2],
    diasCosechaMin: 70, diasCosechaMax: 120,
    agua: 'Moderado-regular (600–1.200 mm/año)',
    suelo: 'Franco, bien drenado, pH 6.0–7.0',
    color: Color(0xFFD32F2F),
    altitudMinM: 0, altitudMaxM: 2000,
    tempMinC: 18, tempMaxC: 30,
    precipMinMm: 600, precipMaxMm: 1200,
    tiposSuelo: ['Franco', 'Franco-arcilloso'],
    phMin: 6.0, phMax: 7.0,
    npk: '15-10-15',
    npkNota: 'K para pungencia y calidad; fraccionar N en 3 aplicaciones',
    paises: ['México', 'Guatemala', 'Honduras', 'Colombia', 'Perú', 'Bolivia', 'Argentina', 'Ecuador'],
    consejos: [
      'Transplantar a los 30–35 días del semillero cuando tenga 4–6 hojas.',
      'Aporcado a los 30 días evita volcamiento y mejora anclaje radicular.',
      'Controlar trips y virosis; son los principales limitantes.',
      'Cosechas escalonadas cada 15–20 días durante 4–6 meses.',
    ],
  ),

  CropInfo(
    id: 'soya', nombre: 'Soya', emoji: '🫛',
    clima: 'Cálido (20–30 °C)', altitud: '0 – 1.500 msnm',
    mesesSiembra: [10, 11, 12, 1, 2],
    mesesCosecha: [2, 3, 4, 5, 6],
    diasCosechaMin: 90, diasCosechaMax: 130,
    agua: 'Moderado (500–1.000 mm/ciclo)',
    suelo: 'Franco, bien drenado, pH 6.0–6.8',
    color: Color(0xFF8BC34A),
    altitudMinM: 0, altitudMaxM: 1500,
    tempMinC: 20, tempMaxC: 30,
    precipMinMm: 500, precipMaxMm: 1000,
    tiposSuelo: ['Franco', 'Franco-arcilloso'],
    phMin: 6.0, phMax: 6.8,
    npk: '5-20-10',
    npkNota: 'Leguminosa: inocular con Bradyrhizobium; mínimo N de arranque (5 kg/ha)',
    paises: ['Brasil', 'Argentina', 'Bolivia', 'Paraguay', 'Colombia', 'México'],
    consejos: [
      'Inocular semilla con Bradyrhizobium para máxima fijación de nitrógeno.',
      'Ajustar pH a 6.0–6.5 con cal antes de siembra en suelos ácidos.',
      'Aplicar molibdeno y cobalto para optimizar fijación de N.',
      'Cosechar con 13–14% de humedad para evitar pérdidas por desgrane.',
    ],
  ),

  CropInfo(
    id: 'cebada', nombre: 'Cebada', emoji: '🌿',
    clima: 'Frío andino (5–15 °C)', altitud: '2.500 – 3.800 msnm',
    mesesSiembra: [9, 10, 11],
    mesesCosecha: [3, 4, 5],
    diasCosechaMin: 120, diasCosechaMax: 160,
    agua: 'Moderado-bajo (400–800 mm/año)',
    suelo: 'Franco, franco-limoso, pH 6.0–7.5',
    color: Color(0xFFAFB42B),
    altitudMinM: 2500, altitudMaxM: 3800,
    tempMinC: 5, tempMaxC: 15,
    precipMinMm: 400, precipMaxMm: 800,
    tiposSuelo: ['Franco', 'Franco-limoso'],
    phMin: 6.0, phMax: 7.5,
    npk: '10-15-10',
    npkNota: 'P en siembra para enraizamiento; N fraccionar en 2 aplicaciones',
    paises: ['Bolivia', 'Perú', 'Colombia', 'Ecuador', 'Argentina', 'Chile'],
    consejos: [
      'Tolera suelos pobres mejor que el trigo; ideal para rotación en altiplano.',
      'Sembrar a 120–150 kg/ha de semilla certificada al voleo o en surcos.',
      'Resistente a heladas en estado vegetativo hasta -8°C.',
      'Cosechar con 14–16% de humedad; trillar en seco para evitar pérdidas.',
    ],
  ),

  CropInfo(
    id: 'arroz', nombre: 'Arroz', emoji: '🍚',
    clima: 'Cálido húmedo (22–35 °C)', altitud: '0 – 1.200 msnm',
    mesesSiembra: [4, 5, 6, 10, 11],
    mesesCosecha: [8, 9, 10, 2, 3],
    diasCosechaMin: 100, diasCosechaMax: 150,
    agua: 'Alto (1.000–3.000 mm/año o irrigación)',
    suelo: 'Arcilloso, franco-arcilloso, pH 5.5–7.0',
    color: Color(0xFFFDD835),
    altitudMinM: 0, altitudMaxM: 1200,
    tempMinC: 22, tempMaxC: 35,
    precipMinMm: 1000, precipMaxMm: 3000,
    tiposSuelo: ['Arcilloso', 'Franco-arcilloso'],
    phMin: 5.5, phMax: 7.0,
    npk: '15-10-10',
    npkNota: 'N en 3 fracciones: macollamiento, primordio, espigamiento; Zn en suelos deficientes',
    paises: ['Brasil', 'Colombia', 'Perú', 'Bolivia', 'Ecuador', 'Venezuela', 'Argentina', 'México'],
    consejos: [
      'Nivelar bien el terreno para manejo uniforme del agua de inundación.',
      'Fertilizar con zinc si el pH supera 7.0 (suelos alcalinos).',
      'Control de malezas en primeros 30 días es crítico para el rendimiento.',
      'Cosechar con 20–22% de humedad y secar a 14% para almacenamiento.',
    ],
  ),

  CropInfo(
    id: 'maracuya', nombre: 'Maracuyá', emoji: '🌺',
    clima: 'Cálido (22–30 °C)', altitud: '0 – 1.500 msnm',
    mesesSiembra: [1, 2, 3, 4, 9, 10],
    mesesCosecha: [6, 7, 8, 9, 1, 2],
    diasCosechaMin: 180, diasCosechaMax: 270,
    agua: 'Moderado-alto (1.000–2.000 mm/año)',
    suelo: 'Franco, bien drenado, pH 5.5–6.5',
    color: Color(0xFFFF8F00),
    altitudMinM: 0, altitudMaxM: 1500,
    tempMinC: 22, tempMaxC: 30,
    precipMinMm: 1000, precipMaxMm: 2000,
    tiposSuelo: ['Franco', 'Franco-arenoso'],
    phMin: 5.5, phMax: 6.5,
    npk: '15-10-20',
    npkNota: 'K para calidad de jugo; aplicar Mg para evitar clorosis intervenal',
    paises: ['Brasil', 'Colombia', 'Ecuador', 'Perú', 'Venezuela', 'Bolivia'],
    consejos: [
      'Instalar espaldera de 2 m de altura antes de plantar.',
      'Requiere polinización cruzada; introducir abejas en floración.',
      'Cosechar cuando el fruto cae naturalmente al suelo (máximo azúcar).',
      'Reemplazar planta cada 3–4 años por disminución de productividad.',
    ],
  ),

  CropInfo(
    id: 'limon', nombre: 'Limón / Citrus', emoji: '🍋',
    clima: 'Cálido-templado (18–30 °C)', altitud: '0 – 1.500 msnm',
    mesesSiembra: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
    mesesCosecha: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
    diasCosechaMin: 180, diasCosechaMax: 360,
    agua: 'Moderado (700–1.500 mm/año)',
    suelo: 'Franco, bien drenado, pH 5.5–7.0',
    color: Color(0xFFF9A825),
    altitudMinM: 0, altitudMaxM: 1500,
    tempMinC: 18, tempMaxC: 30,
    precipMinMm: 700, precipMaxMm: 1500,
    tiposSuelo: ['Franco', 'Franco-arenoso'],
    phMin: 5.5, phMax: 7.0,
    npk: '10-5-15',
    npkNota: 'Fe, Zn y Mn por foliar para corregir clorosis; K para calidad de jugo',
    paises: ['México', 'Colombia', 'Brasil', 'Argentina', 'Perú', 'Ecuador', 'Bolivia'],
    consejos: [
      'Injertar sobre patrón Citrumelo o Volkameriana para resistencia.',
      'Poda de renovación anual para mantener estructura aireada.',
      'Aplicar micronutrientes (Fe, Zn) por vía foliar en suelos de pH >7.',
      'Cosecha escalonada todo el año; mayor producción en épocas secas.',
    ],
  ),
];
