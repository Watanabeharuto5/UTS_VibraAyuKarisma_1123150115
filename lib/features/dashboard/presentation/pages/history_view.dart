import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/cart_provider.dart';

class HistoryView extends StatefulWidget {
  const HistoryView({super.key});

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartProvider>().fetchHistory();
    });
  }

  Future<void> _launchDompetku(String invoice, double total) async {
    final url = Uri.parse(
      'dompetkampus://pay'
      '?merchant_id=koreanpop_store'
      '&merchant_name=KoreanPop%20Album%20Store'
      '&amount=$total'
      '&description=Pembayaran%20pesanan%20$invoice'
      '&reference=$invoice'
      '&callback=koreanpop://payment-callback'
    );

    try {
      final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!launched) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Aplikasi Dompetku (Kantong Saya) gagal dibuka.'),
              backgroundColor: Colors.orangeAccent,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error launching deep link: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aplikasi Dompetku (Kantong Saya) tidak terinstall.'),
            backgroundColor: Colors.orangeAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return switch (cart.status) {
      CartStatus.loading && _ when cart.history.isEmpty => const Center(
          child: CircularProgressIndicator(color: Color(0xFFC8B47A)),
        ),
      CartStatus.error => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Color(0xFFC8B47A)),
              const SizedBox(height: 16),
              Text(
                cart.error ?? 'Gagal memuat riwayat',
                style: const TextStyle(color: Color(0xFF888888)),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => cart.fetchHistory(),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC8B47A)),
                child: const Text('Coba Lagi', style: TextStyle(color: Color(0xFF1A1A1A))),
              ),
            ],
          ),
        ),
      _ when cart.history.isEmpty => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history_outlined, size: 80, color: const Color(0xFFC8B47A).withOpacity(0.5)),
              const SizedBox(height: 16),
              const Text(
                'Belum ada transaksi',
                style: TextStyle(color: Color(0xFF888888), fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      _ => RefreshIndicator(
          color: const Color(0xFFC8B47A),
          backgroundColor: const Color(0xFF1A1A1A),
          onRefresh: () => cart.fetchHistory(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: cart.history.length,
            itemBuilder: (context, i) {
              final trx = cart.history[i];
              
              // Format tanggal GORM ke bentuk yang lebih bersahabat
              String formattedDate = trx.createdAt;
              try {
                final parsed = DateTime.parse(trx.createdAt).toLocal();
                formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(parsed);
              } catch (_) {}

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFC8B47A).withOpacity(0.2),
                    width: 0.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Transaksi
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          trx.invoiceNumber,
                          style: const TextStyle(
                            color: Color(0xFFC8B47A),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Builder(
                          builder: (context) {
                            final statusLower = trx.status.toLowerCase();
                            final isPending = statusLower == 'pending' || statusLower == 'belum bayar';
                            final isCancelled = statusLower == 'batal' || statusLower == 'cancelled';
                            
                            final color = isPending
                                ? Colors.orangeAccent
                                : isCancelled
                                    ? Colors.redAccent
                                    : Colors.greenAccent;
                            final bgColor = isPending
                                ? Colors.orange.withOpacity(0.12)
                                : isCancelled
                                    ? Colors.red.withOpacity(0.12)
                                    : Colors.green.withOpacity(0.12);
                            final borderColor = isPending
                                ? Colors.orange.withOpacity(0.4)
                                : isCancelled
                                    ? Colors.red.withOpacity(0.4)
                                    : Colors.green.withOpacity(0.4);

                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: bgColor,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: borderColor, width: 0.5),
                              ),
                              child: Text(
                                trx.status,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: color,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedDate,
                      style: const TextStyle(color: Color(0xFF666666), fontSize: 11),
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: Color(0xFF222222), height: 1),
                    const SizedBox(height: 12),

                    // Daftar Item dalam Transaksi
                    ...trx.items.map((item) {
                      final p = item.product;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                p.imageUrl,
                                width: 45,
                                height: 45,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 45,
                                  height: 45,
                                  color: const Color(0xFF222222),
                                  child: const Icon(Icons.image_not_supported, size: 18, color: Color(0xFF444444)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: Color(0xFFE8D9B0),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Jumlah: ${item.quantity} x ${NumberFormat.currency(
                                      locale: 'id',
                                      symbol: 'Rp ',
                                      decimalDigits: 0,
                                    ).format(item.price)}',
                                    style: const TextStyle(color: Color(0xFF888888), fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    const Divider(color: Color(0xFF222222), height: 1),
                    const SizedBox(height: 12),

                    // Total Biaya & Metode Pembayaran
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Bayar via: ${trx.paymentMethod}',
                          style: const TextStyle(color: Color(0xFF666666), fontSize: 11),
                        ),
                        Row(
                          children: [
                            const Text(
                              'Total: ',
                              style: TextStyle(color: Color(0xFF888888), fontSize: 12),
                            ),
                            Text(
                              NumberFormat.currency(
                                locale: 'id',
                                symbol: 'Rp ',
                                decimalDigits: 0,
                              ).format(trx.totalPrice),
                              style: const TextStyle(
                                color: Color(0xFFC8B47A),
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (trx.status.toLowerCase() == 'pending') ...[
                      const SizedBox(height: 14),
                      const Divider(color: Color(0xFF222222), height: 1),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 38,
                        child: ElevatedButton(
                          onPressed: () => _launchDompetku(trx.invoiceNumber, trx.totalPrice),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFC8B47A),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text(
                            'Bayar Sekarang',
                            style: TextStyle(
                              color: Color(0xFF1A1A1A),
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
    };
  }
}
