// Arquivo: lib/app_models.dart
// Objetivo didático: concentrar modelos e regras de negócio simples em um
// arquivo separado da interface. Essa organização ajuda o aluno a perceber a
// diferença entre "dados/regras" e "widgets/telas".

/// Representa um usuário autenticado no aplicativo didático.
class AppUser {
  final String name;
  final String email;
  final String profile;

  const AppUser({
    required this.name,
    required this.email,
    required this.profile,
  });
}

/// Representa um produto da loja.
///
/// O produto será carregado do arquivo assets/products.json. A fábrica
/// Product.fromJson converte um Map<String, dynamic> em objeto Dart.
class Product {
  final int id;
  final String name;
  final double price;
  final int stock;
  final String shortDescription;
  final String longDescription;
  final int iconCodePoint;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    required this.shortDescription,
    required this.longDescription,
    required this.iconCodePoint,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      stock: json['stock'] as int,
      shortDescription: json['shortDescription'] as String,
      longDescription: json['longDescription'] as String,
      iconCodePoint: json['iconCodePoint'] as int,
    );
  }
}

/// Representa um item do carrinho.
///
/// Ele guarda o produto selecionado e a quantidade escolhida pelo usuário.
class CartItem {
  final Product product;
  final int quantity;

  const CartItem({
    required this.product,
    required this.quantity,
  });

  double get subtotal => product.price * quantity;

  CartItem copyWith({Product? product, int? quantity}) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }
}

/// Classe utilitária com cálculos do carrinho.
///
/// Como os métodos são static, não precisamos criar um objeto ShoppingMath.
/// Isso facilita o uso em testes automatizados e nas telas do app.
class ShoppingMath {
  static double subtotal(List<CartItem> items) {
    return items.fold(0, (sum, item) => sum + item.subtotal);
  }

  static double shipping(double subtotal) {
    if (subtotal == 0) return 0;
    if (subtotal >= 250) return 0;
    return 18.90;
  }

  static double taxes(double subtotal) {
    return subtotal * 0.08;
  }

  static double total(List<CartItem> items) {
    final subtotalValue = subtotal(items);
    return subtotalValue + shipping(subtotalValue) + taxes(subtotalValue);
  }

  static int clampQuantity(int desiredQuantity, int stock) {
    if (desiredQuantity < 1) return 1;
    if (desiredQuantity > stock) return stock;
    return desiredQuantity;
  }
}

/// Representa um pedido confirmado.
class OrderSummary {
  final String confirmationNumber;
  final String customerName;
  final String billingAddress;
  final String shippingAddress;
  final double subtotal;
  final double shipping;
  final double taxes;
  final double total;

  const OrderSummary({
    required this.confirmationNumber,
    required this.customerName,
    required this.billingAddress,
    required this.shippingAddress,
    required this.subtotal,
    required this.shipping,
    required this.taxes,
    required this.total,
  });
}
