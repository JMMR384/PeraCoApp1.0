import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peraco/features/client/catalog/providers/products_provider.dart';

class CartItem {
  final Product product;
  int cantidad;

  CartItem({required this.product, this.cantidad = 1});

  double get subtotal => product.precio * cantidad;
}

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  void addProduct(Product product) {
    final index = state.indexWhere((item) => item.product.id == product.id);
    if (index >= 0) {
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == index) CartItem(product: state[i].product, cantidad: state[i].cantidad + 1)
          else state[i]
      ];
    } else {
      state = [...state, CartItem(product: product)];
    }
  }

  void removeProduct(String productId) {
    state = state.where((item) => item.product.id != productId).toList();
  }

  void updateCantidad(String productId, int delta) {
    state = [
      for (final item in state)
        if (item.product.id == productId)
          CartItem(product: item.product, cantidad: (item.cantidad + delta).clamp(0, 99))
        else item
    ].where((item) => item.cantidad > 0).toList();
  }

  void clear() => state = [];

  int get totalItems => state.fold(0, (sum, item) => sum + item.cantidad);
  double get subtotal => state.fold(0.0, (sum, item) => sum + item.subtotal);
  double get envio => subtotal > 50000 ? 0 : 5000;
  double get total => subtotal + envio;
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});