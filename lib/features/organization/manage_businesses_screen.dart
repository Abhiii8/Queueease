import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_provider.dart';
import '../auth/auth_provider.dart';
import 'edit_organization_screen.dart';

final myBusinessesProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final user = ref.watch(authProvider).user;
  if (user == null || user['user_id'] == null) return [];

  final response = await ApiClient.get('/organizations/my_businesses.php?user_id=${user['user_id']}');
  if (response.statusCode == 200) {
    return jsonDecode(response.body)['records'];
  } else if (response.statusCode == 404) {
    return [];
  }
  throw Exception('Failed to load businesses');
});

class ManageBusinessesScreen extends ConsumerWidget {
  const ManageBusinessesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businessesAsync = ref.watch(myBusinessesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Manage Businesses', style: TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Inter', fontSize: 18, color: AppColors.textPrimary)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 24),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: businessesAsync.when(
              data: (businesses) {
                if (businesses.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.domain_disabled_rounded, size: 80, color: AppColors.border),
                        const SizedBox(height: 24),
                        const Text(
                          'No Businesses Yet',
                          style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'You haven\'t registered any businesses.',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: () => context.push('/create_org'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.textPrimary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Register a Business', style: TextStyle(fontWeight: FontWeight.w600)),
                        )
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => ref.refresh(myBusinessesProvider.future),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    itemCount: businesses.length,
                    itemBuilder: (context, index) {
                      final org = businesses[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 24, offset: const Offset(0, 12))
                          ],
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Premium Dashboard Header
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: const BoxDecoration(
                                color: Colors.transparent, // Can add gradient here if needed
                                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))
                                      ],
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: org['logo_url'] != null
                                        ? Image.network(
                                            '${ApiClient.baseUrl.split('/backend/api').first}/${org['logo_url']}',
                                            fit: BoxFit.cover,
                                            errorBuilder: (c, e, s) => const Icon(Icons.domain_rounded, color: Colors.white, size: 28),
                                          )
                                        : const Icon(Icons.domain_rounded, color: Colors.white, size: 28),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                org['name'],
                                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary, fontFamily: 'Inter', letterSpacing: -0.5),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: AppColors.success.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: AppColors.success.withOpacity(0.2)),
                                              ),
                                              child: Text(
                                                org['status'] ?? 'ACTIVE',
                                                style: const TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          org['category'],
                                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.edit_rounded, color: AppColors.textSecondary, size: 24),
                                    onPressed: () {
                                      Navigator.push(context, MaterialPageRoute(
                                        builder: (context) => EditOrganizationScreen(organization: org),
                                      ));
                                    },
                                    tooltip: 'Edit Business',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 24),
                                    onPressed: () => _confirmDelete(context, ref, org),
                                    tooltip: 'Delete Business',
                                  ),
                                ],
                              ),
                            ),
                            
                            const Divider(height: 1, color: AppColors.border, thickness: 1),
                            
                            // Dashboard Tiles Section
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  // Use a Wrap for highly responsive tile layout
                                  final double spacing = 16.0;
                                  final double buttonWidth = constraints.maxWidth > 500 
                                      ? (constraints.maxWidth - spacing) / 2 // 2 columns on wide screens
                                      : constraints.maxWidth; // 1 column on small screens

                                  return Wrap(
                                    spacing: spacing,
                                    runSpacing: spacing,
                                    children: [
                                      SizedBox(
                                        width: buttonWidth,
                                        height: 100,
                                        child: _buildActionTile(
                                          icon: Icons.campaign_rounded,
                                          label: 'Live Queue',
                                          color: Colors.white,
                                          bgColor: AppColors.textPrimary,
                                          borderColor: Colors.transparent,
                                          onTap: () => context.push('/admin_queue/${org['org_id']}'),
                                        ),
                                      ),
                                      SizedBox(
                                        width: buttonWidth,
                                        height: 100,
                                        child: _buildActionTile(
                                          icon: Icons.qr_code_scanner_rounded,
                                          label: 'Scan QR Ticket',
                                          color: AppColors.success,
                                          bgColor: Colors.white,
                                          borderColor: AppColors.success.withOpacity(0.3),
                                          onTap: () => context.push('/scan_qr/${org['org_id']}'),
                                        ),
                                      ),
                                      SizedBox(
                                        width: buttonWidth,
                                        height: 100,
                                        child: _buildActionTile(
                                          icon: Icons.analytics_rounded,
                                          label: 'Analytics',
                                          color: AppColors.textPrimary,
                                          bgColor: Colors.white,
                                          borderColor: AppColors.border,
                                          onTap: () => context.push('/analytics/${org['org_id']}'),
                                        ),
                                      ),
                                      SizedBox(
                                        width: buttonWidth,
                                        height: 100,
                                        child: _buildActionTile(
                                          icon: Icons.storefront_rounded,
                                          label: 'Branches',
                                          color: AppColors.textSecondary,
                                          bgColor: AppColors.background,
                                          borderColor: AppColors.border,
                                          onTap: () {
                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Manage Branches coming soon!')));
                                          },
                                        ),
                                      ),
                                    ],
                                  );
                                }
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: AppColors.error))),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, dynamic org) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Business?', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Inter')),
        content: Text('Are you sure you want to delete ${org['name']}? This will permanently delete all branches, queues, and history.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final user = ref.read(authProvider).user;
              if (user == null) return;
              
              try {
                final res = await ApiClient.post('/organizations/delete.php', {
                  'org_id': org['org_id'],
                  'user_id': user['user_id']
                });
                if (res.statusCode == 200) {
                  ref.invalidate(myBusinessesProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Business deleted successfully.'), backgroundColor: AppColors.success));
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete business.'), backgroundColor: AppColors.error));
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
                }
              }
            },
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      )
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 12),
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13, fontFamily: 'Inter', letterSpacing: 0.5)),
            ],
          ),
        ),
      ),
    );
  }
}
