import 'package:flutter_test/flutter_test.dart';
import 'package:revisao_flutter_dart_app/app_models.dart';

void main() {
  group('Product.fromJson', () {
    test('converte JSON em objeto Product', () {
      final product = Product.fromJson({
        'id': 1,
        'name': 'Produto Teste',
        'price': 10.5,
        'stock': 4,
        'shortDescription': 'Curta',
        'longDescription': 'Longa',
        'iconCodePoint': 58167,
      });

      expect(product.id, 1);
      expect(product.name, 'Produto Teste');
      expect(product.price, 10.5);
      expect(product.stock, 4);
    });
  });

  group('ShoppingMath', () {
    final productA = Product(
      id: 1,
      name: 'Produto A',
      price: 100,
      stock: 10,
      shortDescription: 'A',
      longDescription: 'Produto A',
      iconCodePoint: 58167,
    );

    final productB = Product(
      id: 2,
      name: 'Produto B',
      price: 50,
      stock: 10,
      shortDescription: 'B',
      longDescription: 'Produto B',
      iconCodePoint: 57944,
    );

    test('calcula subtotal de itens do carrinho', () {
      final items = [
        CartItem(product: productA, quantity: 2),
        CartItem(product: productB, quantity: 1),
      ];

      expect(ShoppingMath.subtotal(items), 250);
    });

    test('frete é zero para subtotal igual ou maior que 250', () {
      expect(ShoppingMath.shipping(250), 0);
    });

    test('frete é 18.90 para subtotal menor que 250', () {
      expect(ShoppingMath.shipping(100), 18.90);
    });

    test('calcula impostos em 8%', () {
      expect(ShoppingMath.taxes(100), 8);
    });

    test('limita quantidade ao estoque', () {
      expect(ShoppingMath.clampQuantity(15, 8), 8);
      expect(ShoppingMath.clampQuantity(0, 8), 1);
      expect(ShoppingMath.clampQuantity(4, 8), 4);
    });
  });
}
