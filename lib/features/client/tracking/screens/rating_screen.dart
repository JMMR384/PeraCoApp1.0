import 'package:flutter/material.dart';
import 'package:peraco/core/constants/colors.dart';

class RatingScreen extends StatefulWidget {
  final String orderId;
  const RatingScreen({super.key, required this.orderId});
  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  int _currentPage = 0;
  final _pageController = PageController();

  final List<Map<String, dynamic>> _products = [
    {'name': 'Aguacate Hass', 'farm': 'Finca El Paraiso', 'rating': 0, 'issue': '', 'issueOrigin': ''},
    {'name': 'Tomate Chonto', 'farm': 'Finca La Esperanza', 'rating': 0, 'issue': '', 'issueOrigin': ''},
    {'name': 'Limon Tahiti', 'farm': 'Finca San Jose', 'rating': 0, 'issue': '', 'issueOrigin': ''},
  ];

  int _driverRating = 0;
  String _driverComment = '';
  int _generalRating = 0;
  bool _submitting = false;
  bool _submitted = false;

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _submit();
    }
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() { _submitting = false; _submitted = true; });
  }

  @override
  void dispose() { _pageController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (_submitted) return _buildThankYou(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
        title: Text(['Calificar productos', 'Calificar entrega', 'Resumen'][_currentPage]),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
            child: Row(
              children: [
                _PageDot(label: 'Productos', index: 0, current: _currentPage),
                Expanded(child: Container(height: 2, color: _currentPage >= 1 ? PeraCoColors.primary : PeraCoColors.divider)),
                _PageDot(label: 'Entrega', index: 1, current: _currentPage),
                Expanded(child: Container(height: 2, color: _currentPage >= 2 ? PeraCoColors.primary : PeraCoColors.divider)),
                _PageDot(label: 'General', index: 2, current: _currentPage),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (i) => setState(() => _currentPage = i),
              children: [_buildProductsPage(), _buildDriverPage(), _buildGeneralPage()],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, -2))],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _nextPage,
                  style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: _submitting
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                      : Text(_currentPage < 2 ? 'Siguiente' : 'Enviar calificacion'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── HELPER: Fila de peritas ───
  Widget _buildPeraRow({required int rating, required double size, required ValueChanged<int> onRate}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (s) => GestureDetector(
        onTap: () => onRate(s + 1),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: size > 30 ? 6 : 2),
          child: _PeraRating(filled: s < rating, size: size),
        ),
      )),
    );
  }

  // ─── HELPER: Fila mini peritas (no interactiva) ───
  Widget _buildPeraRowMini(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (s) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 1),
        child: _PeraRating(filled: s < rating, size: 16),
      )),
    );
  }

  // ─── PAGINA 1: PRODUCTOS ───
  Widget _buildProductsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Como llegaron tus productos?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Califica la calidad de cada producto', style: TextStyle(color: PeraCoColors.textSecondary, fontSize: 14)),
          const SizedBox(height: 20),
          ...List.generate(_products.length, (i) {
            final product = _products[i];
            final hasIssue = (product['rating'] as int) > 0 && (product['rating'] as int) <= 3;

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: PeraCoColors.surfaceVariant, borderRadius: BorderRadius.circular(14)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(color: PeraCoColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Image.asset('assets/images/icono_peraco.png', fit: BoxFit.contain),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(product['name'] as String, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      Text(product['farm'] as String, style: TextStyle(fontSize: 12, color: PeraCoColors.textSecondary)),
                    ])),
                  ]),
                  const SizedBox(height: 12),
                  _buildPeraRow(
                    rating: product['rating'] as int,
                    size: 36,
                    onRate: (val) => setState(() => _products[i]['rating'] = val),
                  ),
                  const SizedBox(height: 4),
                  Center(child: Text(
                    (product['rating'] as int) == 0 ? 'Toca una pera para calificar' : _getRatingLabel(product['rating'] as int),
                    style: TextStyle(fontSize: 12, color: (product['rating'] as int) == 0 ? PeraCoColors.textHint : PeraCoColors.primary, fontWeight: FontWeight.w500),
                  )),

                  if (hasIssue) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white, borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFFCDD2)),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Row(children: [
                          Icon(Icons.warning_amber_rounded, color: Color(0xFFE53935), size: 18),
                          SizedBox(width: 6),
                          Text('Que problema tuvo el producto?', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        ]),
                        const SizedBox(height: 10),
                        _IssueChip(label: 'Mal estado / no fresco', selected: product['issue'] == 'mal_estado',
                            onTap: () => setState(() => _products[i]['issue'] = 'mal_estado')),
                        const SizedBox(height: 6),
                        _IssueChip(label: 'Golpeado / maltratado', selected: product['issue'] == 'golpeado',
                            onTap: () => setState(() => _products[i]['issue'] = 'golpeado')),
                        const SizedBox(height: 6),
                        _IssueChip(label: 'No corresponde a lo pedido', selected: product['issue'] == 'incorrecto',
                            onTap: () => setState(() => _products[i]['issue'] = 'incorrecto')),
                        const SizedBox(height: 6),
                        _IssueChip(label: 'Cantidad incorrecta', selected: product['issue'] == 'cantidad',
                            onTap: () => setState(() => _products[i]['issue'] = 'cantidad')),

                        if ((product['issue'] as String).isNotEmpty && (product['issue'] == 'golpeado' || product['issue'] == 'mal_estado')) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(10)),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              const Row(children: [
                                Icon(Icons.help_outline, color: Color(0xFFE65100), size: 16),
                                SizedBox(width: 6),
                                Expanded(child: Text('Donde crees que se origino el problema?',
                                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFFE65100)))),
                              ]),
                              const SizedBox(height: 4),
                              Text('Esto nos ayuda a mejorar y resolver tu caso correctamente',
                                  style: TextStyle(fontSize: 11, color: PeraCoColors.textSecondary)),
                              const SizedBox(height: 10),
                              _OriginOption(icon: Icons.agriculture, label: 'Desde la finca',
                                  description: 'El producto ya venia en mal estado',
                                  selected: product['issueOrigin'] == 'finca',
                                  onTap: () => setState(() => _products[i]['issueOrigin'] = 'finca')),
                              const SizedBox(height: 8),
                              _OriginOption(icon: Icons.local_shipping, label: 'Durante el transporte',
                                  description: 'Se dano por mal manejo del PeraGoger',
                                  selected: product['issueOrigin'] == 'transporte',
                                  onTap: () => setState(() => _products[i]['issueOrigin'] = 'transporte')),
                              const SizedBox(height: 8),
                              _OriginOption(icon: Icons.help_outline, label: 'No estoy seguro',
                                  description: 'No puedo determinar el origen',
                                  selected: product['issueOrigin'] == 'no_se',
                                  onTap: () => setState(() => _products[i]['issueOrigin'] = 'no_se')),
                            ]),
                          ),
                        ],
                      ]),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── PAGINA 2: PERAGOGER ───
  Widget _buildDriverPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Como fue la entrega?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Califica a tu PeraGoger', style: TextStyle(color: PeraCoColors.textSecondary, fontSize: 14)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: PeraCoColors.surfaceVariant, borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              CircleAvatar(radius: 28, backgroundColor: PeraCoColors.greenPastel,
                  child: const Text('CR', style: TextStyle(fontWeight: FontWeight.bold, color: PeraCoColors.primary, fontSize: 18))),
              const SizedBox(width: 14),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Carlos Rueda', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                SizedBox(height: 2),
                Text('PeraGoger  •  Moto', style: TextStyle(fontSize: 13, color: PeraCoColors.textSecondary)),
              ])),
            ]),
          ),
          const SizedBox(height: 24),
          _buildPeraRow(rating: _driverRating, size: 44, onRate: (val) => setState(() => _driverRating = val)),
          const SizedBox(height: 8),
          Center(child: Text(
            _driverRating == 0 ? 'Toca una pera para calificar' : _getRatingLabel(_driverRating),
            style: TextStyle(color: _driverRating == 0 ? PeraCoColors.textHint : PeraCoColors.primary, fontWeight: FontWeight.w600),
          )),
          const SizedBox(height: 24),
          Text('Que destaco de la entrega?', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: PeraCoColors.textSecondary)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _QuickTag(label: 'Puntual', icon: Icons.schedule),
            _QuickTag(label: 'Amable', icon: Icons.sentiment_satisfied),
            _QuickTag(label: 'Cuidadoso', icon: Icons.verified_user_outlined),
            _QuickTag(label: 'Buena comunicacion', icon: Icons.chat_outlined),
            _QuickTag(label: 'Productos bien cuidados', icon: Icons.shopping_basket_outlined),
          ]),
          const SizedBox(height: 24),
          Text('Comentario (opcional)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: PeraCoColors.textSecondary)),
          const SizedBox(height: 8),
          TextField(
            maxLines: 3, onChanged: (v) => _driverComment = v,
            decoration: InputDecoration(hintText: 'Cuenta tu experiencia con la entrega...', filled: true,
                fillColor: PeraCoColors.surfaceVariant, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
          ),
        ],
      ),
    );
  }

  // ─── PAGINA 3: GENERAL ───
  Widget _buildGeneralPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Calificacion general', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Como fue tu experiencia con PeraCo?', style: TextStyle(color: PeraCoColors.textSecondary, fontSize: 14)),
          const SizedBox(height: 20),
          _buildPeraRow(rating: _generalRating, size: 44, onRate: (val) => setState(() => _generalRating = val)),
          const SizedBox(height: 8),
          Center(child: Text(
            _generalRating == 0 ? 'Toca una pera para calificar' : _getRatingLabel(_generalRating),
            style: TextStyle(color: _generalRating == 0 ? PeraCoColors.textHint : PeraCoColors.primary, fontWeight: FontWeight.w600),
          )),
          const SizedBox(height: 30),

          // Resumen
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: PeraCoColors.surfaceVariant, borderRadius: BorderRadius.circular(14)),
            child: Column(children: [
              const Row(children: [
                Icon(Icons.summarize_outlined, color: PeraCoColors.primary, size: 20),
                SizedBox(width: 8),
                Text('Resumen de tu calificacion', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              ]),
              const Divider(height: 20),
              ..._products.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  Expanded(child: Text(p['name'] as String, style: const TextStyle(fontSize: 13))),
                  _buildPeraRowMini(p['rating'] as int),
                  if ((p['issue'] as String).isNotEmpty) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.warning_amber_rounded, color: Color(0xFFE53935), size: 16),
                  ],
                ]),
              )),
              const Divider(height: 16),
              Row(children: [
                const Expanded(child: Text('PeraGoger: Carlos Rueda', style: TextStyle(fontSize: 13))),
                _buildPeraRowMini(_driverRating),
              ]),
            ]),
          ),

          // Problemas reportados
          if (_products.any((p) => (p['issue'] as String).isNotEmpty)) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFFE0B2)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Row(children: [
                  Icon(Icons.report_outlined, color: Color(0xFFE65100), size: 20),
                  SizedBox(width: 8),
                  Text('Problemas reportados', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFFE65100))),
                ]),
                const SizedBox(height: 10),
                ..._products.where((p) => (p['issue'] as String).isNotEmpty).map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('• ', style: TextStyle(color: Color(0xFFE65100))),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${p['name']}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      Text(_getIssueLabel(p['issue'] as String), style: TextStyle(fontSize: 12, color: PeraCoColors.textSecondary)),
                      if ((p['issueOrigin'] as String).isNotEmpty)
                        Text('Origen: ${_getOriginLabel(p['issueOrigin'] as String)}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFE65100))),
                    ])),
                  ]),
                )),
                const SizedBox(height: 4),
                Text('Nuestro equipo revisara estos reportes para tomar las medidas correspondientes con el proveedor o PeraGoger según corresponda.',
                    style: TextStyle(fontSize: 11, color: PeraCoColors.textSecondary, fontStyle: FontStyle.italic)),
              ]),
            ),
          ],
        ],
      ),
    );
  }

  String _getRatingLabel(int rating) {
    return ['', 'Muy mal', 'Mal', 'Regular', 'Bien', 'Excelente'][rating];
  }

  String _getIssueLabel(String issue) {
    switch (issue) {
      case 'mal_estado': return 'Producto en mal estado / no fresco';
      case 'golpeado': return 'Producto golpeado / maltratado';
      case 'incorrecto': return 'No corresponde a lo pedido';
      case 'cantidad': return 'Cantidad incorrecta';
      default: return issue;
    }
  }

  String _getOriginLabel(String origin) {
    switch (origin) {
      case 'finca': return 'Desde la finca (responsabilidad del agricultor)';
      case 'transporte': return 'Durante el transporte (responsabilidad del PeraGoger)';
      case 'no_se': return 'No determinado';
      default: return origin;
    }
  }

  Widget _buildThankYou(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120, height: 120,
                decoration: BoxDecoration(color: PeraCoColors.greenPastel, shape: BoxShape.circle),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Image.asset('assets/images/icono_peraco.png', fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 32),
              const Text('Gracias por tu opinion!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text('Tu calificacion nos ayuda a mejorar la calidad de los productos y el servicio de entrega.',
                  style: TextStyle(color: PeraCoColors.textSecondary, height: 1.5), textAlign: TextAlign.center),
              if (_products.any((p) => (p['issue'] as String).isNotEmpty)) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(10)),
                  child: const Row(children: [
                    Icon(Icons.info_outline, color: Color(0xFFE65100), size: 18),
                    SizedBox(width: 8),
                    Expanded(child: Text('Los problemas reportados seran revisados y te contactaremos si es necesario.',
                        style: TextStyle(fontSize: 12, color: Color(0xFFE65100)))),
                  ]),
                ),
              ],
              const SizedBox(height: 40),
              SizedBox(width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: const Text('Volver al inicio'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── WIDGETS ───

class _PeraRating extends StatelessWidget {
  final bool filled;
  final double size;
  const _PeraRating({required this.filled, required this.size});
  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: filled ? 1.0 : 0.2,
      child: Image.asset('assets/images/icono_peraco.png', width: size, height: size, fit: BoxFit.contain),
    );
  }
}

class _PageDot extends StatelessWidget {
  final String label; final int index; final int current;
  const _PageDot({required this.label, required this.index, required this.current});
  @override
  Widget build(BuildContext context) {
    final isActive = current >= index;
    return Column(children: [
      Container(width: 28, height: 28,
          decoration: BoxDecoration(color: isActive ? PeraCoColors.primary : Colors.white, shape: BoxShape.circle,
              border: Border.all(color: isActive ? PeraCoColors.primary : PeraCoColors.divider, width: 2)),
          child: Center(child: isActive && current > index
              ? const Icon(Icons.check, color: Colors.white, size: 16)
              : Text('${index + 1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isActive ? Colors.white : PeraCoColors.textHint)))),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(fontSize: 10, color: isActive ? PeraCoColors.primary : PeraCoColors.textHint)),
    ]);
  }
}

class _IssueChip extends StatelessWidget {
  final String label; final bool selected; final VoidCallback onTap;
  const _IssueChip({required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
            color: selected ? const Color(0xFFFFEBEE) : Colors.white, borderRadius: BorderRadius.circular(8),
            border: Border.all(color: selected ? const Color(0xFFE53935) : PeraCoColors.divider)),
        child: Row(children: [
          Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off, size: 18, color: selected ? const Color(0xFFE53935) : PeraCoColors.textHint),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(fontSize: 13, color: selected ? const Color(0xFFE53935) : PeraCoColors.textPrimary)),
        ]),
      ),
    );
  }
}

class _OriginOption extends StatelessWidget {
  final IconData icon; final String label; final String description; final bool selected; final VoidCallback onTap;
  const _OriginOption({required this.icon, required this.label, required this.description, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: selected ? PeraCoColors.greenPastel : Colors.white, borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? PeraCoColors.primary : PeraCoColors.divider)),
        child: Row(children: [
          Container(width: 36, height: 36,
              decoration: BoxDecoration(color: selected ? PeraCoColors.primary.withOpacity(0.1) : PeraCoColors.surfaceVariant, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 18, color: selected ? PeraCoColors.primary : PeraCoColors.textSecondary)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: selected ? PeraCoColors.primaryDark : PeraCoColors.textPrimary)),
            Text(description, style: TextStyle(fontSize: 11, color: PeraCoColors.textSecondary)),
          ])),
          if (selected) const Icon(Icons.check_circle, color: PeraCoColors.primary, size: 20),
        ]),
      ),
    );
  }
}

class _QuickTag extends StatefulWidget {
  final String label; final IconData icon;
  const _QuickTag({required this.label, required this.icon});
  @override
  State<_QuickTag> createState() => _QuickTagState();
}

class _QuickTagState extends State<_QuickTag> {
  bool _selected = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _selected = !_selected),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
            color: _selected ? PeraCoColors.greenPastel : Colors.white, borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _selected ? PeraCoColors.primary : PeraCoColors.divider)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(widget.icon, size: 16, color: _selected ? PeraCoColors.primary : PeraCoColors.textSecondary),
          const SizedBox(width: 6),
          Text(widget.label, style: TextStyle(fontSize: 12, color: _selected ? PeraCoColors.primaryDark : PeraCoColors.textSecondary,
              fontWeight: _selected ? FontWeight.w600 : FontWeight.normal)),
        ]),
      ),
    );
  }
}