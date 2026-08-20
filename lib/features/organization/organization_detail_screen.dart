import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../auth/auth_provider.dart';

final branchesProvider = FutureProvider.family<List<dynamic>, String>((ref, orgId) async {
  final response = await ApiClient.get('/branches/read.php?org_id=$orgId');
  if (response.statusCode == 200) {
    return jsonDecode(response.body)['records'];
  }
  return [];
});

final servicesProvider = FutureProvider.family<List<dynamic>, String>((ref, branchId) async {
  final response = await ApiClient.get('/services/read.php?branch_id=$branchId');
  if (response.statusCode == 200) {
    return jsonDecode(response.body)['records'];
  }
  return [];
});

class OrganizationDetailScreen extends ConsumerStatefulWidget {
  final String orgId;
  const OrganizationDetailScreen({super.key, required this.orgId});

  @override
  ConsumerState<OrganizationDetailScreen> createState() => _OrganizationDetailScreenState();
}

class _OrganizationDetailScreenState extends ConsumerState<OrganizationDetailScreen> {
  String? selectedBranchId;

  @override
  Widget build(BuildContext context) {
    final branchesAsync = ref.watch(branchesProvider(widget.orgId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Services', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontSize: 18, fontFamily: 'Inter')),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 24),
          onPressed: () => context.pop(),
        ),
      ),
      body: branchesAsync.when(
        data: (branches) {
          if (branches.isEmpty) {
            return const Center(
              child: Text('No branches available.', style: TextStyle(color: AppColors.textSecondary)),
            );
          }

          if (selectedBranchId == null && branches.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                selectedBranchId = branches.first['branch_id'].toString();
              });
            });
          }

          return CustomScrollView(
            slivers: [
              // Branches Selector
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  height: 64,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: branches.length,
                    itemBuilder: (context, index) {
                      final branch = branches[index];
                      final isSelected = selectedBranchId == branch['branch_id'].toString();
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: GestureDetector(
                          onTap: () {
                            setState(() { selectedBranchId = branch['branch_id'].toString(); });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.textPrimary : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isSelected ? AppColors.textPrimary : AppColors.border,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                branch['name'], 
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  color: isSelected ? Colors.white : AppColors.textSecondary,
                                )
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              
              // Divider
              SliverToBoxAdapter(
                child: Container(height: 1, color: AppColors.border),
              ),
              
              // Services List
              if (selectedBranchId != null)
                _ServicesList(branchId: selectedBranchId!),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class _ServicesList extends ConsumerWidget {
  final String branchId;
  const _ServicesList({required this.branchId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(servicesProvider(branchId));

    return servicesAsync.when(
      data: (services) {
        if (services.isEmpty) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: Text('No services available at this branch.', style: TextStyle(color: AppColors.textSecondary))),
            ),
          );
        }
        
        return SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final service = services[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => context.push('/queue/${service['service_id']}'),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: const Icon(Icons.support_agent_rounded, color: AppColors.textSecondary, size: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    service['name'],
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${service['department_name']} • ~${service['average_service_time']} min wait',
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                            if (ref.read(authProvider).user?['role'] == 'ADMIN' || ref.read(authProvider).user?['role'] == 'ORGANIZATION_ADMIN')
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.admin_panel_settings_outlined, color: AppColors.textPrimary, size: 20),
                                  onPressed: () => context.push('/counter/${service['service_id']}'),
                                  tooltip: 'Counter Agent Panel',
                                ),
                              )
                            else
                              const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
              childCount: services.length,
            ),
          ),
        );
      },
      loading: () => const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(40.0), child: CircularProgressIndicator(color: AppColors.primary)))),
      error: (err, stack) => SliverToBoxAdapter(child: Center(child: Text('Error: $err', style: const TextStyle(color: AppColors.error)))),
    );
  }
}
