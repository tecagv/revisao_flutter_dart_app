// Arquivo: lib/main.dart
// Aplicativo: Revisão Flutter e Dart
// Público-alvo: alunos iniciantes do ensino médio técnico em Desenvolvimento de Sistemas
//
// Este projeto revisa, em um único app, os principais temas estudados:
// - estrutura básica do Flutter;
// - widgets Material;
// - navegação;
// - formulário e validação;
// - autenticação simulada;
// - leitura de JSON em assets;
// - lista de produtos;
// - tela de detalhes;
// - carrinho com validação de estoque;
// - cálculo de frete, impostos e total;
// - revisão conceitual de recursos do dispositivo.

import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_models.dart';

Future<void> main() async {
  // Garante que os recursos do Flutter foram inicializados antes de carregar assets.
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RevisionApp());
}

/// Widget principal da aplicação.
///
/// Ele cria uma única instância do AppController, que será compartilhada por
/// todas as telas. Assim o aluno percebe como o estado do app pode ser mantido
/// em memória durante a execução.
class RevisionApp extends StatefulWidget {
  const RevisionApp({super.key});

  @override
  State<RevisionApp> createState() => _RevisionAppState();
}

class _RevisionAppState extends State<RevisionApp> {
  final AppController controller = AppController();

  @override
  void initState() {
    super.initState();
    controller.loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Revisão Flutter e Dart',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
            useMaterial3: true,
          ),
          home: controller.isAuthenticated
              ? HomeShell(controller: controller)
              : LoginPage(controller: controller),
        );
      },
    );
  }
}

/// Controlador geral do app.
///
/// ChangeNotifier permite avisar a interface sempre que alguma informação mudar.
/// Quando chamamos notifyListeners(), os widgets observadores são reconstruídos.
class AppController extends ChangeNotifier {
  AppUser? _currentUser;
  final List<Product> _products = [];
  final Map<int, int> _cartQuantities = {};
  String? _lastError;
  OrderSummary? _lastOrder;
  bool _isLoadingProducts = false;

  AppUser? get currentUser => _currentUser;
  List<Product> get products => List.unmodifiable(_products);
  String? get lastError => _lastError;
  OrderSummary? get lastOrder => _lastOrder;
  bool get isLoadingProducts => _isLoadingProducts;
  bool get isAuthenticated => _currentUser != null;

  /// Converte o Map de quantidades em uma lista de CartItem.
  List<CartItem> get cartItems {
    return _cartQuantities.entries.map((entry) {
      final product = _products.firstWhere((item) => item.id == entry.key);
      return CartItem(product: product, quantity: entry.value);
    }).toList();
  }

  double get subtotal => ShoppingMath.subtotal(cartItems);
  double get shipping => ShoppingMath.shipping(subtotal);
  double get taxes => ShoppingMath.taxes(subtotal);
  double get total => ShoppingMath.total(cartItems);
  int get totalItems => _cartQuantities.values.fold(0, (sum, value) => sum + value);

  /// Autenticação simulada para revisão de Form, validação e navegação condicional.
  bool login({required String email, required String password}) {
    _lastError = null;

    final users = <String, AppUser>{
      'aluno@etec.sp.gov.br': const AppUser(
        name: 'Aluno ETEC',
        email: 'aluno@etec.sp.gov.br',
        profile: 'aluno',
      ),
      'professor@etec.sp.gov.br': const AppUser(
        name: 'Professor Técnico',
        email: 'professor@etec.sp.gov.br',
        profile: 'professor',
      ),
    };

    if (password == '123456' && users.containsKey(email.trim().toLowerCase())) {
      _currentUser = users[email.trim().toLowerCase()];
      notifyListeners();
      return true;
    }

    _lastError = 'E-mail ou senha inválidos. Use aluno@etec.sp.gov.br / 123456.';
    notifyListeners();
    return false;
  }

  void logout() {
    _currentUser = null;
    _lastOrder = null;
    notifyListeners();
  }

  /// Carrega produtos do arquivo assets/products.json.
  Future<void> loadProducts() async {
    _isLoadingProducts = true;
    notifyListeners();

    try {
      final jsonText = await rootBundle.loadString('assets/products.json');
      final decoded = json.decode(jsonText) as List<dynamic>;
      _products
        ..clear()
        ..addAll(decoded.map((item) => Product.fromJson(item as Map<String, dynamic>)));
      _lastError = null;
    } catch (error) {
      _lastError = 'Não foi possível carregar assets/products.json: $error';
    } finally {
      _isLoadingProducts = false;
      notifyListeners();
    }
  }

  /// Adiciona produto ao carrinho, respeitando o estoque disponível.
  void addToCart(Product product) {
    final currentQuantity = _cartQuantities[product.id] ?? 0;

    if (currentQuantity >= product.stock) {
      _lastError = 'Estoque máximo atingido para ${product.name}.';
      notifyListeners();
      return;
    }

    _cartQuantities[product.id] = currentQuantity + 1;
    _lastError = null;
    notifyListeners();
  }

  void increaseQuantity(Product product) {
    addToCart(product);
  }

  void decreaseQuantity(Product product) {
    final currentQuantity = _cartQuantities[product.id] ?? 0;
    if (currentQuantity <= 1) {
      _cartQuantities.remove(product.id);
    } else {
      _cartQuantities[product.id] = currentQuantity - 1;
    }
    _lastError = null;
    notifyListeners();
  }

  void removeFromCart(Product product) {
    _cartQuantities.remove(product.id);
    notifyListeners();
  }

  void clearCart() {
    _cartQuantities.clear();
    _lastOrder = null;
    notifyListeners();
  }

  /// Finaliza o pedido com um número de confirmação didático.
  OrderSummary checkout({
    required String customerName,
    required String billingAddress,
    required String shippingAddress,
  }) {
    final random = Random();
    final confirmation = 'ETEC-${100000 + random.nextInt(899999)}';

    final order = OrderSummary(
      confirmationNumber: confirmation,
      customerName: customerName,
      billingAddress: billingAddress,
      shippingAddress: shippingAddress,
      subtotal: subtotal,
      shipping: shipping,
      taxes: taxes,
      total: total,
    );

    _lastOrder = order;
    _cartQuantities.clear();
    notifyListeners();
    return order;
  }
}

/// Tela de login com Form, TextFormField, controllers e validação.
class LoginPage extends StatefulWidget {
  final AppController controller;

  const LoginPage({super.key, required this.controller});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'aluno@etec.sp.gov.br');
  final _passwordController = TextEditingController(text: '123456');
  bool _hidePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _tryLogin() {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    widget.controller.login(
      email: _emailController.text,
      password: _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.flutter_dash, size: 72, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(height: 12),
                      Text(
                        'Revisão Flutter e Dart',
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Entre para revisar Dart, widgets, produtos, carrinho e recursos do dispositivo.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'E-mail',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          final text = value?.trim() ?? '';
                          if (text.isEmpty) return 'Informe o e-mail.';
                          if (!text.contains('@')) return 'Digite um e-mail válido.';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _hidePassword,
                        decoration: InputDecoration(
                          labelText: 'Senha',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(_hidePassword ? Icons.visibility : Icons.visibility_off),
                            onPressed: () => setState(() => _hidePassword = !_hidePassword),
                          ),
                        ),
                        validator: (value) {
                          if ((value ?? '').length < 6) return 'A senha deve ter pelo menos 6 caracteres.';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _tryLogin,
                        icon: const Icon(Icons.login),
                        label: const Text('Entrar'),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          _emailController.clear();
                          _passwordController.clear();
                        },
                        icon: const Icon(Icons.cleaning_services),
                        label: const Text('Limpar campos'),
                      ),
                      if (widget.controller.lastError != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          widget.controller.lastError!,
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 12),
                      const Text(
                        'Credenciais de teste: aluno@etec.sp.gov.br / 123456',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Estrutura principal após o login.
///
/// NavigationBar controla a troca de páginas sem perder o estado do carrinho.
class HomeShell extends StatefulWidget {
  final AppController controller;

  const HomeShell({super.key, required this.controller});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardPage(controller: widget.controller),
      const DartReviewPage(),
      ProductsPage(controller: widget.controller),
      CartPage(controller: widget.controller),
      const DeviceResourcesReviewPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Atividade Prática de Revisão'),
        actions: [
          Center(child: Text(widget.controller.currentUser?.name ?? '')),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Sair',
            onPressed: widget.controller.logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(child: pages[_selectedIndex]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: [
          const NavigationDestination(icon: Icon(Icons.home), label: 'Início'),
          const NavigationDestination(icon: Icon(Icons.code), label: 'Dart'),
          const NavigationDestination(icon: Icon(Icons.storefront), label: 'Produtos'),
          NavigationDestination(
            icon: Badge(
              label: Text('${widget.controller.totalItems}'),
              isLabelVisible: widget.controller.totalItems > 0,
              child: const Icon(Icons.shopping_cart),
            ),
            label: 'Carrinho',
          ),
          const NavigationDestination(icon: Icon(Icons.smartphone), label: 'Recursos'),
        ],
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  final AppController controller;

  const DashboardPage({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Bem-vindo(a), ${controller.currentUser?.name ?? 'estudante'}!', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        const Text('Use este aplicativo para revisar os principais conceitos de Flutter e Dart antes da avaliação.'),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _SummaryCard(icon: Icons.abc, title: 'Dart', value: 'Tipos, List, Map, funções e classes'),
            _SummaryCard(icon: Icons.widgets, title: 'Flutter', value: 'Scaffold, AppBar, ListView e Card'),
            _SummaryCard(icon: Icons.verified_user, title: 'Login', value: 'Form, validação e sessão'),
            _SummaryCard(icon: Icons.shopping_cart, title: 'Loja', value: 'JSON, carrinho, estoque e total'),
          ],
        ),
        const SizedBox(height: 16),
        _ConceptCard(
          icon: Icons.task_alt,
          title: 'Roteiro de uso em sala',
          body: '1. Entre no app. 2. Revise Dart. 3. Abra Produtos. 4. Adicione itens ao carrinho. 5. Finalize um pedido. 6. Analise o módulo Recursos.',
        ),
        if (controller.lastOrder != null) ...[
          const SizedBox(height: 16),
          _ConceptCard(
            icon: Icons.receipt_long,
            title: 'Último pedido confirmado',
            body: 'Número: ${controller.lastOrder!.confirmationNumber}\nTotal: ${formatCurrency(controller.lastOrder!.total)}',
          ),
        ],
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _SummaryCard({required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 8),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(value),
            ],
          ),
        ),
      ),
    );
  }
}

class DartReviewPage extends StatefulWidget {
  const DartReviewPage({super.key});

  @override
  State<DartReviewPage> createState() => _DartReviewPageState();
}

class _DartReviewPageState extends State<DartReviewPage> {
  int quantity = 2;
  double price = 49.90;
  bool showResult = false;

  @override
  Widget build(BuildContext context) {
    final names = <String>['Ana', 'João', 'Maria'];
    final product = <String, Object>{'nome': 'Livro Dart', 'preco': price};
    final total = calculateSubtotal(price: price, quantity: quantity);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Revisão de Dart', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        const Text('Esta página mostra exemplos rápidos de variáveis, listas, mapas, funções e orientação a objetos.'),
        _ConceptCard(
          icon: Icons.text_fields,
          title: 'String, int, double e bool',
          body: 'String guarda texto. int guarda número inteiro. double guarda número decimal. bool guarda true ou false.',
          code: "String nome = 'Ana';\nint idade = 16;\ndouble preco = 49.90;\nbool ativo = true;",
        ),
        _ConceptCard(
          icon: Icons.list,
          title: 'List',
          body: 'List organiza vários valores em sequência. Exemplo executado nesta tela: ${names.join(', ')}.',
          code: "List<String> nomes = ['Ana', 'João', 'Maria'];",
        ),
        _ConceptCard(
          icon: Icons.map,
          title: 'Map',
          body: 'Map trabalha com pares de chave e valor. Exemplo executado: ${product['nome']} custa ${formatCurrency(product['preco'] as double)}.',
          code: "Map<String, Object> produto = {'nome': 'Livro Dart', 'preco': 49.90};",
        ),
        _ConceptCard(
          icon: Icons.functions,
          title: 'Função',
          body: 'A função calculateSubtotal recebe preço e quantidade, depois devolve o subtotal.',
          code: 'double calculateSubtotal({required double price, required int quantity}) {\n  return price * quantity;\n}',
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Exemplo interativo', style: Theme.of(context).textTheme.titleLarge),
                Text('Quantidade: $quantity'),
                Slider(
                  value: quantity.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  label: '$quantity',
                  onChanged: (value) => setState(() => quantity = value.round()),
                ),
                FilledButton.icon(
                  onPressed: () => setState(() => showResult = true),
                  icon: const Icon(Icons.calculate),
                  label: const Text('Calcular subtotal'),
                ),
                if (showResult) Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text('Subtotal calculado: ${formatCurrency(total)}'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

double calculateSubtotal({required double price, required int quantity}) {
  return price * quantity;
}

class ProductsPage extends StatelessWidget {
  final AppController controller;

  const ProductsPage({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    if (controller.isLoadingProducts) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(controller.lastError ?? 'Nenhum produto encontrado.'),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: controller.products.length,
      itemBuilder: (context, index) {
        final product = controller.products[index];
        return Card(
          child: ListTile(
            leading: Icon(IconData(product.iconCodePoint, fontFamily: 'MaterialIcons'), size: 36),
            title: Text(product.name),
            subtitle: Text('${product.shortDescription}\nPreço: ${formatCurrency(product.price)} | Estoque: ${product.stock}'),
            isThreeLine: true,
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProductDetailsPage(controller: controller, product: product),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class ProductDetailsPage extends StatelessWidget {
  final AppController controller;
  final Product product;

  const ProductDetailsPage({super.key, required this.controller, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes do Produto')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Icon(IconData(product.iconCodePoint, fontFamily: 'MaterialIcons'), size: 96, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 12),
          Text(product.name, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(formatCurrency(product.price), style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          _ConceptCard(
            icon: Icons.info,
            title: 'Descrição',
            body: product.longDescription,
          ),
          _ConceptCard(
            icon: Icons.inventory,
            title: 'Estoque disponível',
            body: '${product.stock} unidade(s). O app não permite adicionar quantidade maior que o estoque.',
          ),
          FilledButton.icon(
            onPressed: () {
              controller.addToCart(product);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(controller.lastError ?? '${product.name} adicionado ao carrinho.')),
              );
            },
            icon: const Icon(Icons.add_shopping_cart),
            label: const Text('Adicionar ao carrinho'),
          ),
        ],
      ),
    );
  }
}

class CartPage extends StatefulWidget {
  final AppController controller;

  const CartPage({super.key, required this.controller});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final _formKey = GlobalKey<FormState>();
  final _customerController = TextEditingController(text: 'Aluno ETEC');
  final _billingController = TextEditingController(text: 'Rua da Escola, 100');
  final _shippingController = TextEditingController(text: 'Rua da Escola, 100');

  @override
  void dispose() {
    _customerController.dispose();
    _billingController.dispose();
    _shippingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.controller.cartItems;

    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.remove_shopping_cart, size: 72),
              const SizedBox(height: 12),
              Text('Carrinho vazio', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              const Text('Abra a tela Produtos e adicione itens para revisar as regras de compra.'),
            ],
          ),
        ),
      );
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Carrinho de Compras', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          ...items.map((item) => Card(
                child: ListTile(
                  title: Text(item.product.name),
                  subtitle: Text('Qtd.: ${item.quantity} | Subtotal: ${formatCurrency(item.subtotal)}'),
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      IconButton(
                        tooltip: 'Diminuir',
                        onPressed: () => widget.controller.decreaseQuantity(item.product),
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      IconButton(
                        tooltip: 'Aumentar',
                        onPressed: () => widget.controller.increaseQuantity(item.product),
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                      IconButton(
                        tooltip: 'Remover',
                        onPressed: () => widget.controller.removeFromCart(item.product),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                ),
              )),
          const SizedBox(height: 8),
          _TotalBox(controller: widget.controller),
          const SizedBox(height: 16),
          TextFormField(
            controller: _customerController,
            decoration: const InputDecoration(labelText: 'Nome do cliente', border: OutlineInputBorder()),
            validator: requiredText,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _billingController,
            decoration: const InputDecoration(labelText: 'Endereço de cobrança', border: OutlineInputBorder()),
            validator: requiredText,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _shippingController,
            decoration: const InputDecoration(labelText: 'Endereço de entrega', border: OutlineInputBorder()),
            validator: requiredText,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              final valid = _formKey.currentState?.validate() ?? false;
              if (!valid) return;
              final order = widget.controller.checkout(
                customerName: _customerController.text,
                billingAddress: _billingController.text,
                shippingAddress: _shippingController.text,
              );
              showDialog<void>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Pedido confirmado'),
                  content: Text('Número: ${order.confirmationNumber}\nTotal: ${formatCurrency(order.total)}'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.check_circle),
            label: const Text('Finalizar pedido'),
          ),
          TextButton.icon(
            onPressed: widget.controller.clearCart,
            icon: const Icon(Icons.cancel),
            label: const Text('Cancelar pedido e limpar carrinho'),
          ),
        ],
      ),
    );
  }
}

class _TotalBox extends StatelessWidget {
  final AppController controller;

  const _TotalBox({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TotalLine(label: 'Subtotal', value: controller.subtotal),
            _TotalLine(label: 'Frete', value: controller.shipping),
            _TotalLine(label: 'Impostos (8%)', value: controller.taxes),
            const Divider(),
            _TotalLine(label: 'Total', value: controller.total, highlight: true),
          ],
        ),
      ),
    );
  }
}

class _TotalLine extends StatelessWidget {
  final String label;
  final double value;
  final bool highlight;

  const _TotalLine({required this.label, required this.value, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    final style = highlight ? Theme.of(context).textTheme.titleMedium : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(formatCurrency(value), style: style),
        ],
      ),
    );
  }
}

class DeviceResourcesReviewPage extends StatelessWidget {
  const DeviceResourcesReviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final resources = [
      _ResourceInfo(
        icon: Icons.camera_alt,
        title: 'Câmera',
        concept: 'O app usa plugin para solicitar acesso à câmera, exibir preview e capturar imagem.',
        packageName: 'camera',
      ),
      _ResourceInfo(
        icon: Icons.screen_rotation_alt,
        title: 'Sensores',
        concept: 'Sensores como acelerômetro e giroscópio geram leituras de movimento do aparelho.',
        packageName: 'sensors_plus',
      ),
      _ResourceInfo(
        icon: Icons.location_on,
        title: 'GPS e mapas',
        concept: 'A localização depende de permissão do usuário e de serviços de localização ativos.',
        packageName: 'geolocator + url_launcher',
      ),
      _ResourceInfo(
        icon: Icons.sms,
        title: 'Telefone e SMS',
        concept: 'O app pode abrir aplicativos nativos, como discador e SMS, usando intents/URLs.',
        packageName: 'url_launcher',
      ),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Revisão de recursos do dispositivo', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        const Text('Este projeto não aciona hardware real. Ele revisa os conceitos antes de usar plugins em um app específico.'),
        const SizedBox(height: 12),
        ...resources.map((item) => _ResourceCard(info: item)),
      ],
    );
  }
}

class _ResourceInfo {
  final IconData icon;
  final String title;
  final String concept;
  final String packageName;

  const _ResourceInfo({required this.icon, required this.title, required this.concept, required this.packageName});
}

class _ResourceCard extends StatelessWidget {
  final _ResourceInfo info;

  const _ResourceCard({required this.info});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(info.icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(info.title, style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 8),
            Text(info.concept),
            const SizedBox(height: 8),
            Text('Pacote usado em projeto real: ${info.packageName}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Simulação: ${info.title} revisado com sucesso.')),
                );
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Simular revisão'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConceptCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final String? code;

  const _ConceptCard({required this.icon, required this.title, required this.body, this.code});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
              ],
            ),
            const SizedBox(height: 8),
            Text(body),
            if (code != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(code!, style: const TextStyle(fontFamily: 'monospace')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String? requiredText(String? value) {
  if ((value ?? '').trim().isEmpty) return 'Campo obrigatório.';
  return null;
}

String formatCurrency(double value) {
  return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
}
