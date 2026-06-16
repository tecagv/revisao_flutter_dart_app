# Revisão Flutter e Dart - Atividade Prática

Aplicativo didático para revisão dos conteúdos de Flutter e Dart no ensino médio técnico.

### Prof. Alexandre Garcez Vieira - ETEC JK

## Conteúdos revisados

- Estrutura básica de um projeto Flutter.
- Widgets Material: `MaterialApp`, `Scaffold`, `AppBar`, `Card`, `ListView`, `TextFormField`, `NavigationBar`.
- Linguagem Dart: variáveis, tipos, listas, mapas, funções, classes e objetos.
- Formulário, validação e autenticação simulada.
- Controle de estado com `ChangeNotifier` e `AnimatedBuilder`.
- Leitura de arquivo JSON em `assets/products.json`.
- Catálogo de produtos, detalhes, carrinho, validação de estoque e finalização de pedido.
- Revisão conceitual de câmera, sensores, GPS/mapas, telefone e SMS.

## Como executar

1. Abra o terminal na pasta do projeto.
2. Execute:

```bash
flutter pub get
flutter run
```

Se as pastas nativas Android/iOS não existirem no seu ambiente, execute antes:

```bash
flutter create .
flutter pub get
flutter run
```

## Credenciais de teste

- `aluno@etec.sp.gov.br` / `123456`
- `professor@etec.sp.gov.br` / `123456`

## Testes automatizados

```bash
flutter test
```

Os testes estão em `test/app_models_test.dart` e validam conversão de JSON, subtotal, frete, impostos e limite de quantidade por estoque.

## Observação técnica

Este pacote contém o código-fonte completo do app didático. No ambiente de geração deste material não havia Flutter SDK instalado, portanto a verificação foi feita por revisão estática do código, conferência da estrutura de arquivos e testes lógicos preparados para execução com `flutter test` no ambiente do aluno/professor.
