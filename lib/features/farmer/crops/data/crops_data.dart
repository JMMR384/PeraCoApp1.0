import 'package:flutter/material.dart';

class CropInfo {
  final String id;
  final String nombre;
  final String emoji;
  final String clima;
  final String altitud;
  final List<int> mesesSiembra; // 1-12
  final List<int> mesesCosecha; // 1-12
  final int diasCosechaMin;
  final int diasCosechaMax;
  final String agua;
  final String suelo;
  final List<String> consejos;
  final Color color;

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

  String get diasLabel => '$diasCosechaMin – $diasCosechaMax dias';
}

const List<CropInfo> cropsData = [
  CropInfo(
    id: 'papa', nombre: 'Papa', emoji: '🥔',
    clima: 'Frio (6–14 °C)', altitud: '2.000 – 3.200 msnm',
    mesesSiembra: [2, 3, 4, 8, 9, 10],
    mesesCosecha: [5, 6, 7, 11, 12, 1],
    diasCosechaMin: 90, diasCosechaMax: 120,
    agua: 'Moderado (500–700 mm/ciclo)',
    suelo: 'Franco, bien drenado, pH 5.0–6.5',
    color: Color(0xFF8D6E63),
    consejos: [
      'Rotar cultivo cada 2–3 años para evitar enfermedades del suelo.',
      'Aplicar fungicidas preventivos contra gota (Phytophthora infestans).',
      'Aporcar las plantas a los 30 dias para estimular la tuberización.',
      'Cosechar en dias secos; dejar curar 1 semana antes de almacenar.',
    ],
  ),
  CropInfo(
    id: 'fresa', nombre: 'Fresa', emoji: '🍓',
    clima: 'Frio moderado (14–20 °C)', altitud: '1.500 – 2.200 msnm',
    mesesSiembra: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
    mesesCosecha: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
    diasCosechaMin: 60, diasCosechaMax: 90,
    agua: 'Frecuente (riego por goteo ideal)',
    suelo: 'Franco-arenoso, bien drenado, pH 5.5–6.5',
    color: Color(0xFFE53935),
    consejos: [
      'Plantar en camas elevadas (30 cm) para mejorar drenaje y aireación.',
      'Usar acolchado plastico negro para controlar malezas y conservar humedad.',
      'Cosechar cada 2–3 dias en temporada alta.',
      'Renovar plantas cada 2–3 años para mantener productividad.',
    ],
  ),
  CropInfo(
    id: 'tomate', nombre: 'Tomate', emoji: '🍅',
    clima: 'Calido-templado (18–26 °C)', altitud: '0 – 2.000 msnm',
    mesesSiembra: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
    mesesCosecha: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
    diasCosechaMin: 70, diasCosechaMax: 90,
    agua: 'Regular (evitar encharcamiento)',
    suelo: 'Franco, rico en materia organica, pH 5.5–6.8',
    color: Color(0xFFEF6C00),
    consejos: [
      'Tutorear las plantas a los 20 cm de altura con estacas o espalderas.',
      'Podar chupones laterales semanalmente para concentrar producción.',
      'Vigilar mosca blanca y acaros; aplicar neem oil preventivo.',
      'Cosechar antes de lluvias fuertes para evitar rajaduras.',
    ],
  ),
  CropInfo(
    id: 'arveja', nombre: 'Arveja', emoji: '🫛',
    clima: 'Frio (10–18 °C)', altitud: '2.000 – 3.000 msnm',
    mesesSiembra: [2, 3, 8, 9],
    mesesCosecha: [5, 6, 11, 12],
    diasCosechaMin: 90, diasCosechaMax: 120,
    agua: 'Moderado (evitar exceso)',
    suelo: 'Franco-limoso, bien drenado, pH 6.0–7.0',
    color: Color(0xFF388E3C),
    consejos: [
      'Inocular semilla con Rhizobium para fijar nitrógeno y reducir fertilizante.',
      'Usar mallas o estacas desde el inicio para sostener el guia.',
      'Cosechar en verde (vaina turgente) para consumo fresco.',
      'Para semilla seca, esperar hasta que la vaina se torne amarilla.',
    ],
  ),
  CropInfo(
    id: 'zanahoria', nombre: 'Zanahoria', emoji: '🥕',
    clima: 'Frio (14–20 °C)', altitud: '1.800 – 2.800 msnm',
    mesesSiembra: [2, 3, 4, 8, 9, 10],
    mesesCosecha: [5, 6, 7, 11, 12, 1],
    diasCosechaMin: 90, diasCosechaMax: 120,
    agua: 'Regular y uniforme',
    suelo: 'Franco-arenoso, profundo y suelto, pH 6.0–6.8',
    color: Color(0xFFFF8F00),
    consejos: [
      'Desmenuzar el suelo a 30 cm de profundidad; piedras deforman la raiz.',
      'Sembrar en hileras a 5 cm entre plantas; ralear a los 15 dias.',
      'Evitar abonos organicos frescos (causan bifurcacion de raices).',
      'Cosechar cuando el hombro verde sea visible en la superficie.',
    ],
  ),
  CropInfo(
    id: 'cebolla', nombre: 'Cebolla larga', emoji: '🧅',
    clima: 'Frio-templado (12–22 °C)', altitud: '1.800 – 2.800 msnm',
    mesesSiembra: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
    mesesCosecha: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
    diasCosechaMin: 120, diasCosechaMax: 150,
    agua: 'Regular (goteo o aspersion)',
    suelo: 'Franco, suelto, bien drenado, pH 6.0–7.0',
    color: Color(0xFF7B1FA2),
    consejos: [
      'Usar hijuelos de buena calidad, desinfectados antes de siembra.',
      'Fertilizar con alto contenido de potasio para engrosar el tallo.',
      'Aporcar a los 30 dias para blanquear el tallo y mejorar calidad.',
      'Cosechar cuando el 50% de las plantas tengan el follaje doblado.',
    ],
  ),
  CropInfo(
    id: 'lechuga', nombre: 'Lechuga', emoji: '🥬',
    clima: 'Frio-templado (15–20 °C)', altitud: '1.500 – 2.500 msnm',
    mesesSiembra: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
    mesesCosecha: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
    diasCosechaMin: 45, diasCosechaMax: 60,
    agua: 'Frecuente y ligero',
    suelo: 'Franco, rico en materia organica, pH 6.0–7.0',
    color: Color(0xFF558B2F),
    consejos: [
      'Transplantar plántulas de 20–25 dias de almácigo.',
      'Evitar encharcamiento; causa pudricion de cuello.',
      'Cosechar en la mañana para mayor frescura y vida util.',
      'Escalonar siembras cada 15 dias para producción continua.',
    ],
  ),
  CropInfo(
    id: 'maiz', nombre: 'Maiz', emoji: '🌽',
    clima: 'Calido-templado (20–30 °C)', altitud: '0 – 1.800 msnm',
    mesesSiembra: [3, 4, 5, 9, 10],
    mesesCosecha: [6, 7, 8, 12, 1],
    diasCosechaMin: 90, diasCosechaMax: 120,
    agua: 'Moderado-alto en floración',
    suelo: 'Franco, profundo, bien drenado, pH 5.5–7.0',
    color: Color(0xFFF9A825),
    consejos: [
      'Densidad de siembra: 50.000–60.000 plantas/ha en surcos a 80 cm.',
      'Aplicar nitrogeno fraccionado: 30% siembra, 70% en V6.',
      'Controlar gusano cogollero (Spodoptera) desde germinación.',
      'Maiz tierno: cosechar 20 dias despues de la floración femenina.',
    ],
  ),
  CropInfo(
    id: 'mora', nombre: 'Mora de Castilla', emoji: '🫐',
    clima: 'Frio moderado (12–18 °C)', altitud: '1.500 – 2.400 msnm',
    mesesSiembra: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
    mesesCosecha: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
    diasCosechaMin: 180, diasCosechaMax: 240,
    agua: 'Moderado y uniforme',
    suelo: 'Franco-arcilloso, bien drenado, pH 5.5–6.5',
    color: Color(0xFF6A1B9A),
    consejos: [
      'Instalar tutores en espaldera (2 alambres a 0.8 y 1.4 m de altura).',
      'Podar ramas cosechadas; dejar 3–4 ramas nuevas por planta.',
      'Cosechar en estado pintón-maduro para mejor precio en mercado.',
      'Producción continua después de 8–10 meses; vida util 8–10 años.',
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
    consejos: [
      'Injerto sobre patron tolerante a Phytophthora para mayor vigor.',
      'Poda de formación los primeros 2 años; luego solo sanitaria.',
      'Determinar cosecha por porcentaje de aceite (mínimo 8–11%).',
      'Un arbol adulto puede producir 200–400 frutos por cosecha.',
    ],
  ),
  CropInfo(
    id: 'cafe', nombre: 'Cafe', emoji: '☕',
    clima: 'Templado (17–23 °C)', altitud: '1.200 – 1.800 msnm',
    mesesSiembra: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
    mesesCosecha: [9, 10, 11, 12, 1, 2],
    diasCosechaMin: 180, diasCosechaMax: 270,
    agua: 'Bien distribuido (1.800–2.800 mm/año)',
    suelo: 'Franco-arcilloso, rico en materia organica, pH 5.0–6.5',
    color: Color(0xFF5D4037),
    consejos: [
      'Variedad Colombia o Castillo son resistentes a roya.',
      'Cosechar solo granos maduros (rojo-cereza) para mejor calidad.',
      'Despulpar en las primeras 8 horas post-cosecha.',
      'Renovar plantación cada 7–10 años mediante zoca.',
    ],
  ),
  CropInfo(
    id: 'platano', nombre: 'Platano', emoji: '🍌',
    clima: 'Calido (20–30 °C)', altitud: '0 – 1.200 msnm',
    mesesSiembra: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
    mesesCosecha: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
    diasCosechaMin: 270, diasCosechaMax: 365,
    agua: 'Alto (1.800–2.500 mm/año)',
    suelo: 'Franco, profundo, bien drenado, pH 5.5–7.0',
    color: Color(0xFFF57F17),
    consejos: [
      'Deshijar dejando un hijo de espada por planta para continuidad.',
      'Defoliar hojas secas y desflorecer el pinzon para mayor calibre.',
      'Cosechar con 75% de llenado (angulos redondeados en los dedos).',
      'Empacar en hojas para proteger en transporte y mejorar precio.',
    ],
  ),
];
