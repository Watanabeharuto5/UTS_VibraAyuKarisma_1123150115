import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HistoryView extends StatelessWidget {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    // Data riwayat transaksi mock yang estetik dan lengkap
    final List<Map<String, dynamic>> mockHistory = [
      {
        'id': 'TRX-99812-KP',
        'date': '02 Jul 2026, 14:30',
        'items': 'TREASURE - 2ND FULL ALBUM [REBOOT] PHOTOBOOK VER. (Set)',
        'quantity': 1,
        'price': 650000.0,
        'status': 'Selesai',
        'image': 'https://i.ibb.co.com/zWvcRg9S/reboot.png',
      },
      {
        'id': 'TRX-98765-KP',
        'date': '28 Jun 2026, 10:15',
        'items': 'BTS - \'ARIRANG\' (Set) + Weverse Albums ver.',
        'quantity': 1,
        'price': 900000.0,
        'status': 'Selesai',
        'image': 'https://i.ibb.co.com/Y4sBGRJm/arirang2.png',
      },
      {
        'id': 'TRX-95541-KP',
        'date': '15 Jun 2026, 18:45',
        'items': 'NCT DREAM - [DREAM( )SCAPE] (QR Ver.)',
        'quantity': 2,
        'price': 280000.0,
        'status': 'Selesai',
        'image': 'https://i.ibb.co.com/x8qWVf1t/nctdream.jpg',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: mockHistory.length,
      itemBuilder: (context, i) {
        final trx = mockHistory[i];
        final totalTrx = trx['price'] as double;

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
                    trx['id'],
                    style: const TextStyle(
                      color: Color(0xFFC8B47A),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.withOpacity(0.4), width: 0.5),
                    ),
                    child: Text(
                      trx['status'],
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                trx['date'],
                style: const TextStyle(color: Color(0xFF666666), fontSize: 11),
              ),
              const SizedBox(height: 12),
              const Divider(color: Color(0xFF222222), height: 1),
              const SizedBox(height: 12),

              // Item Transaksi
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      trx['image'],
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 50,
                        height: 50,
                        color: const Color(0xFF222222),
                        child: const Icon(Icons.image_not_supported, size: 20, color: Color(0xFF444444)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trx['items'],
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
                          'Jumlah: ${trx['quantity']} x ${NumberFormat.currency(
                            locale: 'id',
                            symbol: 'Rp ',
                            decimalDigits: 0,
                          ).format(totalTrx / trx['quantity'])}',
                          style: const TextStyle(color: Color(0xFF888888), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(color: Color(0xFF222222), height: 1),
              const SizedBox(height: 12),

              // Total Biaya
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Transaksi',
                    style: TextStyle(color: Color(0xFF888888), fontSize: 12),
                  ),
                  Text(
                    NumberFormat.currency(
                      locale: 'id',
                      symbol: 'Rp ',
                      decimalDigits: 0,
                    ).format(totalTrx),
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
        );
      },
    );
  }
}
