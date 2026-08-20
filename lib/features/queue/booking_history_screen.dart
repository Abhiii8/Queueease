import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../auth/auth_provider.dart';

import 'package:qr_flutter/qr_flutter.dart';

final bookingHistoryProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final user = ref.watch(authProvider).user;
  if (user == null) return [];
  
  final response = await ApiClient.get('/bookings/read.php?user_id=${user['user_id']}');
  if (response.statusCode == 200) {
    return jsonDecode(response.body)['records'];
  }
  return [];
});

class BookingHistoryScreen extends ConsumerWidget {
  const BookingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(bookingHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Bookings', style: TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Inter', fontSize: 18, color: AppColors.textPrimary)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: SafeArea(
        child: historyAsync.when(
          data: (bookings) {
            if (bookings.isEmpty) {
              return const Center(child: Text('You have no booking history.', style: TextStyle(color: AppColors.textSecondary)));
            }
            return RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: Colors.white,
              onRefresh: () => ref.refresh(bookingHistoryProvider.future),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24).copyWith(bottom: 120),
                child: SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    spacing: 24,
                    runSpacing: 24,
                    alignment: WrapAlignment.start,
                    crossAxisAlignment: WrapCrossAlignment.start,
                    children: bookings.map((b) {
                      return ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 450),
                        child: BookingCard(booking: b),
                      );
                    }).toList(),
                  ),
                ),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: AppColors.error))),
        ),
      ),
    );
  }
}

class BookingCard extends StatefulWidget {
  final Map<String, dynamic> booking;
  const BookingCard({super.key, required this.booking});

  @override
  State<BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends State<BookingCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final isActive = b['status'] == 'WAITING' || b['status'] == 'CALLED' || b['status'] == 'SERVING';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 24, offset: const Offset(0, 12))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isActive ? () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            } : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Ticket Header (Dark Mode)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TOKEN NUMBER',
                            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5, fontFamily: 'Inter'),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            b['token_number'],
                            style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, fontFamily: 'Inter', letterSpacing: -1.0),
                          ),
                        ],
                      ),
                      _buildDarkStatusChip(b['status']),
                    ],
                  ),
                ),
                
                // Ticket Body (Light Mode)
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.business_rounded, color: AppColors.primary, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  b['org_name'],
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.textPrimary, letterSpacing: -0.5, fontFamily: 'Inter'),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  b['service_name'],
                                  style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          const Icon(Icons.access_time_filled_rounded, color: AppColors.textSecondary, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            b['booked_at'],
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutQuart,
                        child: _isExpanded && isActive ? Column(
                          children: [
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Divider(color: AppColors.border, height: 1, thickness: 1),
                            ),
                            const Center(
                              child: Text(
                                'SHOW THIS QR AT THE COUNTER',
                                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, letterSpacing: 1.0, fontSize: 11),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Center(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppColors.border, width: 2),
                                  boxShadow: [
                                    BoxShadow(color: AppColors.primary.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 8))
                                  ],
                                ),
                                child: QrImageView(
                                  data: b['qr_verification_id'] ?? 'invalid',
                                  version: QrVersions.auto,
                                  size: 180.0,
                                  foregroundColor: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ) : const SizedBox.shrink(),
                      ),
                      
                      if (isActive && !_isExpanded)
                        const Padding(
                          padding: EdgeInsets.only(top: 20),
                          child: Center(
                            child: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary, size: 28),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDarkStatusChip(String status) {
    Color color = Colors.white;
    Color bgColor = Colors.white.withOpacity(0.2);
    
    if (status == 'WAITING') {
      color = const Color(0xFFFBBF24);
      bgColor = const Color(0xFFFBBF24).withOpacity(0.2);
    }
    if (status == 'CALLED' || status == 'SERVING') {
      color = const Color(0xFF34D399); // Light green for dark background
      bgColor = const Color(0xFF34D399).withOpacity(0.2);
    }
    if (status == 'CANCELLED' || status == 'NO_SHOW') {
      color = const Color(0xFFF87171); // Light red for dark background
      bgColor = const Color(0xFFF87171).withOpacity(0.2);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5, fontFamily: 'Inter'),
      ),
    );
  }
}
