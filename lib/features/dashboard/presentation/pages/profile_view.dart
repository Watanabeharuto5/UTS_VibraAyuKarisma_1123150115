import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/routes/app_router.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.firebaseUser;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),

          // Foto Profil / Avatar Estetik K-Pop Theme
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFC8B47A), width: 1.5),
            ),
            child: CircleAvatar(
              radius: 50,
              backgroundColor: const Color(0xFF1A1A1A),
              backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
              child: user?.photoURL == null
                  ? const Icon(Icons.person, size: 50, color: Color(0xFFC8B47A))
                  : null,
            ),
          ),
          const SizedBox(height: 16),

          // Nama Pengguna
          Text(
            user?.displayName ?? 'Pengguna Setia',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFFE8D9B0),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),

          // Peran / Role Tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFC8B47A).withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFC8B47A).withOpacity(0.3), width: 0.5),
            ),
            child: const Text(
              'VIP Member',
              style: TextStyle(
                fontSize: 10,
                color: Color(0xFFC8B47A),
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Kartu Informasi Akun
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
              children: [
                _buildInfoRow(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: user?.email ?? '-',
                ),
                const Divider(color: Color(0xFF222222), height: 24),
                _buildInfoRow(
                  icon: Icons.verified_user_outlined,
                  label: 'Status Email',
                  value: (user?.emailVerified ?? false) ? 'Terverifikasi' : 'Belum Verifikasi',
                  valueColor: (user?.emailVerified ?? false) ? Colors.greenAccent : Colors.orangeAccent,
                ),
                const Divider(color: Color(0xFF222222), height: 24),
                _buildInfoRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Bergabung Sejak',
                  value: user?.metadata.creationTime != null
                      ? '${user!.metadata.creationTime!.day}/${user.metadata.creationTime!.month}/${user.metadata.creationTime!.year}'
                      : '-',
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Tombol Logout Premium
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.logout, color: Colors.redAccent, size: 20),
              label: const Text(
                'Keluar dari Akun',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.redAccent.withOpacity(0.5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                await auth.logout();
                if (!context.mounted) return;
                Navigator.pushReplacementNamed(context, AppRouter.login);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFC8B47A), size: 20),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Color(0xFF666666), fontSize: 11),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                color: valueColor ?? const Color(0xFFE8D9B0),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
