import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/cart_provider.dart';
import '../../../../core/routes/app_router.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String _selectedMethod = 'Kantong Saya';
  bool _isProcessing = false;
  bool _isSuccess = false;
  bool _waitingForCallback = false;
  String _currentInvoice = '';

  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'name': 'Kantong Saya',
      'icon': Icons.wallet,
      'instructions': '1. Klik Bayar Sekarang\n2. Anda akan diarahkan ke aplikasi Kantong Saya secara otomatis\n3. Lakukan pembayaran di aplikasi Kantong Saya.',
    },
    {
      'name': 'GoPay',
      'icon': Icons.account_balance_wallet_outlined,
      'instructions': '1. Buka aplikasi Gojek\n2. Pilih Bayar / Scan QR\n3. Konfirmasi pembayaran Anda.',
    },
    {
      'name': 'Virtual Account BCA',
      'icon': Icons.account_balance,
      'instructions': '1. Transfer ke nomor VA: 8001001123150115\n2. Masukkan nominal yang sesuai\n3. Simpan bukti transaksi.',
    },
    {
      'name': 'Virtual Account Mandiri',
      'icon': Icons.account_balance,
      'instructions': '1. Transfer ke nomor VA: 8002001123150115\n2. Masukkan nominal yang sesuai\n3. Simpan bukti transaksi.',
    },
  ];

  String _formattedAmount(dynamic amount) {
    final numVal = amount is num ? amount : 0.0;
    return NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(numVal);
  }

  Future<void> _launchDompetku(Map<String, dynamic>? txData) async {
    if (txData == null) return;
    final invoice = txData['invoice_number'] ?? '';
    final total = (txData['total_price'] as num?)?.toDouble() ?? 0.0;
    
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aplikasi Dompetku (Kantong Saya) gagal dibuka.'),
            backgroundColor: Colors.orangeAccent,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error launching deep link: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aplikasi Dompetku (Kantong Saya) tidak terinstall.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
    }
  }

  Future<void> _processPayment() async {
    setState(() {
      _isProcessing = true;
    });

    final cart = context.read<CartProvider>();
    final success = await cart.checkout(_selectedMethod);

    setState(() {
      _isProcessing = false;
    });

    if (success) {
      final txData = cart.lastCheckoutData ?? {};
      final invoice = txData['invoice_number'] ?? '';
      
      setState(() {
        _currentInvoice = invoice;
        _waitingForCallback = true;
      });

      await _launchDompetku(txData);
    } else {
      final errorMsg = cart.error ?? 'Pembayaran gagal';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    if (_waitingForCallback && cart.lastPaidInvoice == _currentInvoice) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _isSuccess = true;
          _waitingForCallback = false;
        });
      });
    }

    if (_isSuccess) {
      return Scaffold(
        backgroundColor: const Color(0xFF111111),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFC8B47A).withOpacity(0.12),
                    border: Border.all(color: const Color(0xFFC8B47A), width: 2),
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    size: 80,
                    color: Color(0xFFC8B47A),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Pembayaran Berhasil!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFE8D9B0),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Pesanan Anda sedang diproses. Silakan cek menu Riwayat Transaksi secara berkala.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: const Color(0xFF888888),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      // Kembali ke dashboard (rute /dashboard)
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRouter.dashboard,
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC8B47A),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text(
                      'Kembali ke Beranda',
                      style: TextStyle(
                        color: Color(0xFF1A1A1A),
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_waitingForCallback) {
      return Scaffold(
        backgroundColor: const Color(0xFF111111),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A1A1A),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFFC8B47A)),
            onPressed: () {
              setState(() {
                _waitingForCallback = false;
                _currentInvoice = '';
              });
            },
          ),
          title: const Text(
            'Menunggu Pembayaran',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFFE8D9B0),
              letterSpacing: 1.0,
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    color: Color(0xFFC8B47A),
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Menunggu Pembayaran',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFE8D9B0),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Silakan lakukan pembayaran sebesar ${_formattedAmount(cart.lastCheckoutData?['total_price'])} untuk invoice $_currentInvoice di aplikasi Kantong Saya.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF888888),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => _launchDompetku(cart.lastCheckoutData),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC8B47A),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text(
                      'Buka Aplikasi Kantong Saya',
                      style: TextStyle(
                        color: Color(0xFF1A1A1A),
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _waitingForCallback = false;
                      _currentInvoice = '';
                    });
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Batalkan dan Kembali',
                    style: TextStyle(
                      color: Color(0xFFC8B47A),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final activeMethod = _paymentMethods.firstWhere((m) => m['name'] == _selectedMethod);

    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFC8B47A)),
          onPressed: _isProcessing ? null : () => Navigator.pop(context),
        ),
        title: const Text(
          'Metode Pembayaran',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFFE8D9B0),
            letterSpacing: 1.5,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: const Color(0xFFC8B47A).withOpacity(0.3)),
        ),
      ),
      body: _isProcessing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFFC8B47A)),
                  SizedBox(height: 16),
                  Text(
                    'Memproses Pembayaran Anda...',
                    style: TextStyle(color: Color(0xFF888888), fontSize: 14),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Rincian Pesanan',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFE8D9B0),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
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
                        ...cart.cartItems.map((item) {
                          final p = item.product;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    '${p.name} (x${item.quantity})',
                                    style: const TextStyle(
                                      color: Color(0xFFE8D9B0),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  NumberFormat.currency(
                                    locale: 'id',
                                    symbol: 'Rp ',
                                    decimalDigits: 0,
                                  ).format(p.price * item.quantity),
                                  style: const TextStyle(
                                    color: Color(0xFFC8B47A),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        const Divider(color: Color(0xFF222222), height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Tagihan',
                              style: TextStyle(
                                color: Color(0xFF888888),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              NumberFormat.currency(
                                locale: 'id',
                                symbol: 'Rp ',
                                decimalDigits: 0,
                              ).format(cart.totalPrice),
                              style: const TextStyle(
                                color: Color(0xFFC8B47A),
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Pilih Metode Pembayaran',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFE8D9B0),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Daftar Metode Pembayaran
                  ..._paymentMethods.map((method) {
                    final isSelected = method['name'] == _selectedMethod;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedMethod = method['name'];
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFC8B47A).withOpacity(0.06) : const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? const Color(0xFFC8B47A) : const Color(0xFFC8B47A).withOpacity(0.1),
                            width: isSelected ? 1 : 0.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              method['icon'] as IconData,
                              color: isSelected ? const Color(0xFFC8B47A) : const Color(0xFF888888),
                              size: 24,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                method['name'] as String,
                                style: TextStyle(
                                  color: isSelected ? const Color(0xFFE8D9B0) : const Color(0xFF888888),
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle, color: Color(0xFFC8B47A), size: 20),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 24),

                  // Petunjuk Pembayaran
                  const Text(
                    'Petunjuk Pembayaran',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFE8D9B0),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF222222), width: 0.5),
                    ),
                    child: Text(
                      activeMethod['instructions'] as String,
                      style: const TextStyle(
                        color: Color(0xFF888888),
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Tombol Bayar Sekarang
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _processPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC8B47A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text(
                        'Bayar Sekarang',
                        style: TextStyle(
                          color: Color(0xFF1A1A1A),
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
