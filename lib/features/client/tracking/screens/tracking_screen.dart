import 'package:flutter/material.dart';
import 'package:peraco/core/constants/colors.dart';
import 'package:peraco/features/client/tracking/screens/rating_screen.dart';

class TrackingScreen extends StatefulWidget {
  final String orderId;
  const TrackingScreen({super.key, required this.orderId});
  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> with TickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  // Simula el estado actual del pedido (0.0 a 1.0)
  // En produccion esto viene de Supabase en tiempo real
  int _currentStatus = 2; // Cambia para probar diferentes estados

  final List<Map<String, dynamic>> _statuses = [
    {'label': 'Pedido confirmado', 'icon': Icons.check_circle_outline, 'time': '1:32 PM'},
    {'label': 'Preparando tu pedido', 'icon': Icons.inventory_2_outlined, 'time': '1:35 PM'},
    {'label': 'PeraGoger en camino a recoger', 'icon': Icons.local_shipping_outlined, 'time': '1:42 PM'},
    {'label': 'Pedido recogido', 'icon': Icons.shopping_basket_outlined, 'time': ''},
    {'label': 'En camino a tu direccion', 'icon': Icons.directions_bike_outlined, 'time': ''},
    {'label': 'Entregado', 'icon': Icons.home_outlined, 'time': ''},
  ];

  double get _progressValue => _currentStatus / (_statuses.length - 1);

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: _progressValue).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );
    _progressController.forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  void _simulateNextStep() {
    if (_currentStatus < _statuses.length - 1) {
      final oldValue = _progressValue;
      setState(() => _currentStatus++);
      _progressAnimation = Tween<double>(begin: oldValue, end: _progressValue).animate(
        CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
      );
      _progressController.reset();
      _progressController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDelivered = _currentStatus == _statuses.length - 1;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        title: Text('Pedido #${widget.orderId}'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Estado actual destacado
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDelivered ? PeraCoColors.greenPastel : PeraCoColors.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDelivered ? PeraCoColors.primary : PeraCoColors.primary.withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          isDelivered ? Icons.check_circle : (_statuses[_currentStatus]['icon'] as IconData),
                          size: 48,
                          color: PeraCoColors.primary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _statuses[_currentStatus]['label'] as String,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: PeraCoColors.primaryDark),
                          textAlign: TextAlign.center,
                        ),
                        if (!isDelivered) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Tiempo estimado: 25 min',
                            style: TextStyle(fontSize: 13, color: PeraCoColors.textSecondary),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Barra de progreso continua
                  AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      return Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: SizedBox(
                              height: 12,
                              child: Stack(
                                children: [
                                  // Fondo
                                  Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: PeraCoColors.surfaceVariant,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  // Progreso
                                  FractionallySizedBox(
                                    widthFactor: _progressAnimation.value,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [PeraCoColors.primaryLight, PeraCoColors.primary],
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Confirmado', style: TextStyle(fontSize: 10, color: PeraCoColors.textHint)),
                              Text('Entregado', style: TextStyle(fontSize: 10, color: PeraCoColors.textHint)),
                            ],
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 28),

                  // Timeline de estados
                  Text('Detalle del seguimiento', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),

                  ...List.generate(_statuses.length, (i) {
                    final status = _statuses[i];
                    final isCompleted = i <= _currentStatus;
                    final isCurrent = i == _currentStatus;
                    final isLast = i == _statuses.length - 1;

                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Linea vertical + punto
                          SizedBox(
                            width: 32,
                            child: Column(
                              children: [
                                Container(
                                  width: isCurrent ? 20 : 14,
                                  height: isCurrent ? 20 : 14,
                                  decoration: BoxDecoration(
                                    color: isCompleted ? PeraCoColors.primary : PeraCoColors.surfaceVariant,
                                    shape: BoxShape.circle,
                                    border: isCurrent ? Border.all(color: PeraCoColors.primary, width: 3) : null,
                                    boxShadow: isCurrent
                                        ? [BoxShadow(color: PeraCoColors.primary.withOpacity(0.3), blurRadius: 8, spreadRadius: 2)]
                                        : null,
                                  ),
                                  child: isCompleted && !isCurrent
                                      ? const Icon(Icons.check, color: Colors.white, size: 10)
                                      : null,
                                ),
                                if (!isLast)
                                  Container(
                                    width: 2,
                                    height: 40,
                                    color: isCompleted && i < _currentStatus ? PeraCoColors.primary : PeraCoColors.divider,
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Info del estado
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    status['label'] as String,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                                      color: isCompleted ? PeraCoColors.textPrimary : PeraCoColors.textHint,
                                    ),
                                  ),
                                  if ((status['time'] as String).isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      status['time'] as String,
                                      style: TextStyle(fontSize: 12, color: PeraCoColors.textSecondary),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 16),

                  // Info del Peragoger
                  if (_currentStatus >= 2) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: PeraCoColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: PeraCoColors.greenPastel,
                            child: const Text('CR', style: TextStyle(fontWeight: FontWeight.bold, color: PeraCoColors.primary)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Carlos Rueda', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(Icons.star, color: Color(0xFFFFC107), size: 16),
                                    const SizedBox(width: 4),
                                    Text('4.8', style: TextStyle(fontSize: 13, color: PeraCoColors.textSecondary)),
                                    const SizedBox(width: 8),
                                    Text('Moto', style: TextStyle(fontSize: 13, color: PeraCoColors.textSecondary)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(color: PeraCoColors.primary, borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.phone, color: Colors.white, size: 22),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Direccion de entrega
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: PeraCoColors.divider),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(color: PeraCoColors.greenPastel, borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.location_on_outlined, color: PeraCoColors.primary, size: 22),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Casa', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              Text('Calle 45 #12-34, Bogota', style: TextStyle(fontSize: 12, color: PeraCoColors.textSecondary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Boton inferior (simular avance o calificar)
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, -2))],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: isDelivered
                    ? ElevatedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RatingScreen(orderId: widget.orderId))),
                  icon: const Icon(Icons.star_outline, size: 20),
                  label: const Text('Calificar pedido'),
                  style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                )
                    : OutlinedButton.icon(
                  onPressed: _simulateNextStep,
                  icon: const Icon(Icons.skip_next, size: 20),
                  label: const Text('Simular siguiente paso'),
                  style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}