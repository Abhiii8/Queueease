import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../auth/auth_provider.dart';
import 'organization_provider.dart';

final activeBookingProvider = StreamProvider.autoDispose<Map<String, dynamic>?>((ref) async* {
  final user = ref.watch(authProvider).user;
  if (user == null || user['user_id'] == null) {
    yield null;
    return;
  }

  while (true) {
    try {
      final response = await ApiClient.get('/bookings/read.php?user_id=${user['user_id']}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final records = data['records'] as List<dynamic>;
        final active = records.firstWhere(
          (b) => b['status'] == 'WAITING' || b['status'] == 'CALLED',
          orElse: () => null,
        );
        yield active;
      } else {
        yield null;
      }
    } catch (_) {
      // Ignore error
    }
    await Future.delayed(const Duration(seconds: 5));
  }
});

class SelectedCategoryNotifier extends Notifier<String> {
  @override
  String build() => 'All';

  void setCategory(String category) {
    state = category;
  }
}

final selectedCategoryProvider = NotifierProvider<SelectedCategoryNotifier, String>(() {
  return SelectedCategoryNotifier();
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  final List<String> categories = const ['All', 'Hospital', 'Bank', 'Restaurant', 'Public Office', 'Retail'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final orgsAsync = ref.watch(organizationsProvider);
    final activeBookingAsync = ref.watch(activeBookingProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('QueueEase', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textPrimary, fontSize: 22, letterSpacing: -0.5, fontFamily: 'Inter')),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: IconButton(
              icon: const Icon(Icons.person_outline, color: AppColors.textPrimary, size: 20),
              onPressed: () => context.push('/profile'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: Colors.white,
              onRefresh: () async {
                ref.invalidate(organizationsProvider);
              },
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    authState.user?['name']?.substring(0, 1).toUpperCase() ?? 'G',
                                    style: const TextStyle(color: AppColors.primary, fontSize: 20, fontWeight: FontWeight.w800, fontFamily: 'Inter'),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Good morning, ${authState.user?['name']?.split(' ')[0] ?? 'Guest'}',
                                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary, fontFamily: 'Inter', letterSpacing: -0.5),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Discover places and join queues instantly.',
                                      style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          
                          // Active Ticket Widget
                          activeBookingAsync.when(
                            data: (booking) {
                              if (booking == null) return const SizedBox.shrink();
                              return _buildActiveTicketWidget(context, booking);
                            },
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                          
                          // Premium Search Bar
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
                              ],
                            ),
                            child: const TextField(
                              decoration: InputDecoration(
                                hintText: 'Search for hospitals, banks...',
                                hintStyle: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w500, fontSize: 15),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                prefixIcon: Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 22),
                                contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                                filled: false,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),

              // Categories Row
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 40,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final isSelected = selectedCategory == category;
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: InkWell(
                          onTap: () => ref.read(selectedCategoryProvider.notifier).setCategory(category),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.textPrimary : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: isSelected ? AppColors.textPrimary : AppColors.border),
                              boxShadow: isSelected ? [BoxShadow(color: AppColors.textPrimary.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))] : [],
                            ),
                            child: Text(
                              category,
                              style: TextStyle(
                                color: isSelected ? Colors.white : AppColors.textSecondary,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),

              orgsAsync.when(
                data: (orgs) {
                  final filteredOrgs = selectedCategory == 'All' 
                      ? orgs 
                      : orgs.where((org) => org['category'] == selectedCategory).toList();

                  if (filteredOrgs.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
                        child: Center(
                          child: Column(
                            children: [
                              const Icon(Icons.business_center_outlined, size: 48, color: AppColors.border),
                              const SizedBox(height: 16),
                              Text(
                                'No Places Found',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildListDelegate([
                      if (selectedCategory == 'All') ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24),
                          child: Text('Featured', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary, fontFamily: 'Inter')),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 260,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            scrollDirection: Axis.horizontal,
                            itemCount: filteredOrgs.length > 3 ? 3 : filteredOrgs.length,
                            itemBuilder: (context, index) {
                              return _buildFeaturedOrgCard(context, filteredOrgs[index]);
                            },
                          ),
                        ),
                        const SizedBox(height: 40),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24),
                          child: Text('All Places', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary, fontFamily: 'Inter')),
                        ),
                        const SizedBox(height: 16),
                      ] else ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text('$selectedCategory Places', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary, fontFamily: 'Inter')),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: filteredOrgs.map((org) => _buildPremiumOrgCard(context, org)).toList(),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ]),
                  );
                },
                loading: () => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: 50.0),
                    child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  ),
                ),
                error: (err, stack) => SliverToBoxAdapter(
                  child: Center(
                    child: Text('Error loading organizations: $err', style: const TextStyle(color: AppColors.error)),
                  ),
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

  Widget _buildFeaturedOrgCard(BuildContext context, Map<String, dynamic> org) {
    return Container(
      width: 240,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => context.push('/org/${org['org_id']}'),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: org['logo_url'] != null
                          ? Image.network('${ApiClient.baseUrl.split('/backend/api').first}/${org['logo_url']}', fit: BoxFit.cover, errorBuilder: (c, e, s) => const Center(child: Icon(Icons.business_rounded, color: AppColors.primary, size: 28)))
                          : const Center(child: Icon(Icons.business_rounded, color: AppColors.primary, size: 28)),
                    ),
                    if (org['allows_scheduling'] == 1 || org['allows_scheduling'] == '1')
                      Positioned(
                        bottom: -8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
                            ],
                          ),
                          child: const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 14),
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                Text(
                  org['name'] ?? '',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary, fontFamily: 'Inter'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(org['category'] ?? '', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                      child: const Text('OPEN', style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTicketWidget(BuildContext context, Map<String, dynamic> booking) {
    final isCalled = booking['status'] == 'CALLED';

    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      decoration: BoxDecoration(
        color: isCalled ? AppColors.success : AppColors.textPrimary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isCalled ? AppColors.success : AppColors.textPrimary).withOpacity(0.3), 
            blurRadius: 20, 
            offset: const Offset(0, 10)
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => context.push('/tracking'),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isCalled ? 'YOUR TURN' : 'ACTIVE PASS', 
                        style: const TextStyle(
                          color: Colors.white, 
                          fontSize: 10, 
                          fontWeight: FontWeight.w800, 
                          letterSpacing: 1.5,
                          fontFamily: 'Inter',
                        )
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54, size: 16),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  booking['org_name'] ?? 'Organization', 
                  style: const TextStyle(
                    color: Colors.white, 
                    fontSize: 22, 
                    fontWeight: FontWeight.w800, 
                    fontFamily: 'Inter',
                    letterSpacing: -0.5,
                  ), 
                  overflow: TextOverflow.ellipsis
                ),
                const SizedBox(height: 24),
                Row(
                  children: List.generate(
                    30,
                    (index) => Expanded(
                      child: Container(
                        height: 1,
                        color: index % 2 == 0 ? Colors.white.withOpacity(0.3) : Colors.transparent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('TOKEN', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
                        const SizedBox(height: 4),
                        Text('${booking['token_number']}', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, fontFamily: 'Inter')),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('EST. WAIT', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text('${booking['estimated_waiting_time']}', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, fontFamily: 'Inter')),
                            Text('m', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumOrgCard(BuildContext context, Map<String, dynamic> org) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push('/org/${org['org_id']}'),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: org['logo_url'] != null
                          ? Image.network('${ApiClient.baseUrl.split('/backend/api').first}/${org['logo_url']}', fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.business_rounded, color: AppColors.textSecondary, size: 24))
                          : const Icon(Icons.business_rounded, color: AppColors.textSecondary, size: 24),
                    ),
                    if (org['allows_scheduling'] == 1 || org['allows_scheduling'] == '1')
                      Positioned(
                        bottom: -4,
                        right: -4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 10),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        org['name'] ?? '',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontFamily: 'Inter'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            org['category'] ?? '',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.circle, color: AppColors.border, size: 4),
                          const SizedBox(width: 12),
                          const Icon(Icons.check_circle, color: AppColors.success, size: 12),
                          const SizedBox(width: 4),
                          const Text(
                            'Open',
                            style: TextStyle(color: AppColors.success, fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
