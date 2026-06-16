# Prompt para usar no Codex

Você é um desenvolvedor Flutter/Dart sênior e professor de desenvolvimento de aplicativos móveis para ensino médio técnico. Revise o projeto `revisao_flutter_dart_app` com foco didático e técnico.

Verifique obrigatoriamente:

1. Se `pubspec.yaml` registra corretamente `assets/products.json`.
2. Se `lib/app_models.dart` possui modelos claros e testáveis.
3. Se `lib/main.dart` executa login simulado com validação de formulário.
4. Se a navegação por `NavigationBar` funciona sem perder o estado do carrinho.
5. Se a tela Produtos carrega o JSON por `rootBundle`.
6. Se a tela Detalhes adiciona produtos ao carrinho sem ultrapassar o estoque.
7. Se o carrinho calcula subtotal, frete, impostos e total corretamente.
8. Se a finalização do pedido valida nome e endereços.
9. Se os comentários estão didáticos e adequados a alunos iniciantes.
10. Se os testes em `test/app_models_test.dart` estão corretos.

Depois, execute ou oriente a execução dos comandos:

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Caso encontre erro, corrija o código mantendo linguagem clara e comentários pedagógicos.
