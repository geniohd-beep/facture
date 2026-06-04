import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../models/product.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _stockColor(int stock) {
    if (stock <= 0) return Colors.red;
    if (stock >= 100) return Colors.green;
    final ratio = stock / 100.0;
    return Color.lerp(Colors.orange, Colors.green, ratio)!;
  }

  Widget _stockBadge(int stock) {
    final color = _stockColor(stock);
    final bg = color.withValues(alpha: 0.15);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            stock <= 0 ? Icons.error_outline : Icons.inventory_2,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            '$stock',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Productos'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/products/form'),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Buscar producto...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) {
                if (v.length >= 2) {
                  context.read<ProductProvider>().searchProducts(v);
                } else {
                  context.read<ProductProvider>().loadProducts();
                }
                setState(() {});
              },
            ),
          ),
          Expanded(
            child: Consumer<ProductProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final products = _searchController.text.length >= 2
                    ? provider.searchResults
                    : provider.products;

                if (products.isEmpty) {
                  return const Center(child: Text('No hay productos registrados'));
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Text(
                        'Productos disponibles (${products.length})',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final product = products[index];
                          return _buildProductCard(product);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    final stockColor = _stockColor(product.stock);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: stockColor.withValues(alpha: 0.15),
          child: Text(
            product.name.isNotEmpty ? product.name[0].toUpperCase() : 'P',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: stockColor,
            ),
          ),
        ),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Código: ${product.code} | ${product.unitType}',
                style: const TextStyle(fontSize: 12)),
            Text(
              'S/ ${product.salePrice.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: _stockBadge(product.stock),
        onTap: () => Navigator.pushNamed(
          context,
          '/products/form',
          arguments: product,
        ),
      ),
    );
  }
}
