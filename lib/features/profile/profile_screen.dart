import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../auth/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Inter', fontSize: 18, color: AppColors.textPrimary)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(left: 24, right: 24, top: 32, bottom: 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
              // Avatar
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 2),
                  ),
                  child: const Icon(Icons.person_outline_rounded, size: 48, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 24),
              
              // Name and Email
              Text(
                user?['name'] ?? 'User',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                user?['email'] ?? 'No email',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500, fontSize: 14),
              ),
              const SizedBox(height: 16),
              
              // Role Badge
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: user?['role'] == 'ORG_ADMIN' ? AppColors.success.withOpacity(0.1) : AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: user?['role'] == 'ORG_ADMIN' ? AppColors.success.withOpacity(0.3) : AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Text(
                    user?['role'] ?? 'USER',
                    style: TextStyle(
                      color: user?['role'] == 'ORG_ADMIN' ? AppColors.success : AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      letterSpacing: 0.5,
                      fontFamily: 'Inter'
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 48),

              // Menu Options
              const Text('ACCOUNT', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.0)),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
                  ],
                ),
                child: Column(
                  children: [
                    _buildMenuOption(
                      context: context,
                      icon: Icons.business_center_outlined,
                      title: 'Register a Business',
                      subtitle: 'Create a new queue for your organization.',
                      onTap: () {
                        context.push('/create_org');
                      },
                    ),
                    if (user?['role'] == 'ORG_ADMIN' || user?['role'] == 'SUPER_ADMIN')
                      Column(
                        children: [
                          const Divider(height: 1, color: AppColors.border),
                          _buildMenuOption(
                            context: context,
                            icon: Icons.dashboard_outlined,
                            title: 'Manage My Businesses',
                            subtitle: 'Access the admin dashboard.',
                            onTap: () {
                              context.push('/manage_businesses');
                            },
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
                  ],
                ),
                child: _buildMenuOption(
                  context: context,
                  icon: Icons.logout_rounded,
                  title: 'Sign Out',
                  subtitle: 'Log out of your account securely.',
                  iconColor: AppColors.error,
                  onTap: () {
                    ref.read(authProvider.notifier).logout();
                    context.go('/login');
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);
  }

  Widget _buildMenuOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color iconColor = AppColors.textPrimary,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: iconColor == AppColors.error ? AppColors.error : AppColors.textPrimary, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}
