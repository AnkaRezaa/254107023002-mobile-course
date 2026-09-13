// kode Praktikum 3 — Uji ketiga state



import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'pages/product_page.dart';

class ProductsNotifier extends AsyncNotifier<List<String>> {
  @override
  // Future<List<String>> build() async {
  //   await Future.delayed(const Duration(seconds: 2));
  //   return ['Keyboard', 'Mouse', 'Monitor'];
  // }
  Future<List<String>> build() async {
  throw Exception('Gagal terhubung ke server');
}

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch());
  }

  Future<List<String>> _fetch() async {
    await Future.delayed(const Duration(seconds: 1));
    return ['Keyboard', 'Mouse', 'Monitor', 'Headset'];
  }


  
}

final productsProvider =
    AsyncNotifierProvider<ProductsNotifier, List<String>>(ProductsNotifier.new);

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const ProductPage(),
    );
  }
}