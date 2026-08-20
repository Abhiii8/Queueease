import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../auth/auth_provider.dart';
import '../organization/home_screen.dart';

final queueStatusProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, serviceId) async {
  final response = await ApiClient.get('/queues/status.php?service_id=$serviceId');
  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to load queue status');
  }
});

class QueueBookingScreen extends ConsumerStatefulWidget {
  final String serviceId;
  const QueueBookingScreen({super.key, required this.serviceId});

  @override
  ConsumerState<QueueBookingScreen> createState() => _QueueBookingScreenState();
}

class _QueueBookingScreenState extends ConsumerState<QueueBookingScreen> {
  bool _isBooking = false;

  Future<void> _bookToken(Map<String, dynamic> queue, Map<String, dynamic>? user) async {
    if (user == null || user['user_id'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please login to book a token.')));
      return;
    }

    setState(() => _isBooking = true);

    try {
      final response = await ApiClient.post('/bookings/create.php', {
        'service_id': widget.serviceId,
        'user_id': user['user_id'],
      });
      
      if (response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Token booked successfully!', style: TextStyle(fontWeight: FontWeight.w600)),
            backgroundColor: AppColors.success,
          ));
          context.push('/tracking');
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(jsonDecode(response.body)['message'] ?? 'Failed to book token'),
            backgroundColor: AppColors.error,
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Network error. Please try again.'),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) {
        setState(() => _isBooking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(queueStatusProvider(widget.serviceId));
    final activeBookingAsync = ref.watch(activeBookingProvider);
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Queue Details', style: TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Inter', fontSize: 18, color: AppColors.textPrimary)),
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
      body: statusAsync.when(
        data: (queue) {
          final tokenPrefix = queue['token_prefix'] ?? 'A';
          final currentlyServing = '$tokenPrefix-${queue['current_token_number']}';
          final waiting = queue['total_waiting'];
          final avgTime = queue['average_service_time'];
          final estimatedWait = waiting * avgTime;

          return SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Service Header
                        Text(
                          queue['service_name'],
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            fontSize: 24,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Avg service time: $avgTime mins',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 48),

                        // Main Currently Serving Card
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
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
                          child: Column(
                            children: [
                              const Text(
                                'CURRENTLY SERVING',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.0,
                                  fontFamily: 'Inter',
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                currentlyServing,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 64,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'Inter',
                                  height: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Stats Row
                        Row(
                          children: [
                            Expanded(
                              child: _buildDetailCard(
                                icon: Icons.people_alt_outlined,
                                title: 'Waiting',
                                value: waiting.toString(),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildDetailCard(
                                icon: Icons.timer_outlined,
                                title: 'Est. Wait',
                                value: '$estimatedWait m',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Bottom Action Area
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: const Border(top: BorderSide(color: AppColors.border)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, -4))
                    ],
                  ),
                  child: SafeArea(
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: activeBookingAsync.when(
                        data: (booking) {
                          final hasActive = booking != null;
                          if (hasActive) {
                            return ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColors.textPrimary,
                                elevation: 0,
                                side: const BorderSide(color: AppColors.border),
                              ),
                              onPressed: () => context.push('/tracking'),
                              child: const Text('VIEW ACTIVE TICKET', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                            );
                          }
                          return ElevatedButton(
                            onPressed: _isBooking ? null : () => _bookToken(queue, user),
                            child: _isBooking 
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Book My Token', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, stack) => Center(
          child: Column(
           mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.textSecondary),
              const SizedBox(height: 16),
              const Text('Queue unavailable.', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.border),
                  elevation: 0,
                ),
                onPressed: () => context.pop(),
                child: const Text('Go Back')
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailCard({required IconData icon, required String title, required String value}) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 24),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w700, fontFamily: 'Inter')),
        ],
      ),
    );
  }
}
