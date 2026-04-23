@override
Widget build(BuildContext context) {
  final product = context.watch<ProductProvider>();

  return Scaffold(
    appBar: AppBar(title: const Text('Dashboard')),

    body: switch (product.status) {
      // 🔄 Loading / pertama kali buka
      ProductStatus.loading || ProductStatus.initial =>
        const Center(child: CircularProgressIndicator()),

      // ❌ Error
      ProductStatus.error => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(product.error ?? 'Terjadi kesalahan'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => product.fetchProducts(),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),

      // ✅ Success → tampilkan produk
      ProductStatus.loaded => GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: product.products.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        itemBuilder: (_, i) {
          final p = product.products[i];
          return _ProductCard(product: p);
        },
      ),
    },
  );
}