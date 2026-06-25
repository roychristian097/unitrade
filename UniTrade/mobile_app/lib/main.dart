import 'dart:convert'; // Huruf 'i' harus kecil
import 'package:http/http.dart' as http; 
import 'package:flutter/material.dart';
import 'login_page.dart'; // Import file login

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UniTrade App',
      debugShowCheckedModeBanner: false, 
      theme: ThemeData(
        brightness: Brightness.dark, 
      ),
      home: const LoginPage(), // Menjadikan LoginPage sebagai halaman utama
    );
  }
}

// ==========================================
// KODE DI BAWAH INI ADALAH HALAMAN PRODUK
// (Sementara tidak ditampilkan karena home-nya adalah LoginPage)
// ==========================================

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  
  Future<List<Product>> fetchProducts() async {
    final response = await http.get(Uri.parse('http://127.0.0.1:8000/products'));

    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return jsonResponse.map((product) => Product.fromJson(product)).toList();
    } else {
      throw Exception('Gagal memuat produk');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Toko UniTrade")),
      body: FutureBuilder<List<Product>>(
        future: fetchProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(snapshot.data![index].name),
                  subtitle: Text("Rp ${snapshot.data![index].price}"),
                  leading: const Icon(Icons.shopping_bag),
                );
              },
            );
          }
        },
      ),
    );
  }
}

class Product {
  final String name;
  final int price;

  Product({required this.name, required this.price});

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(name: json['name'], price: json['price']);
  }
}