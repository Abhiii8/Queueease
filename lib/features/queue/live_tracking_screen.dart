import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../auth/auth_provider.dart';

// Provides continuous polling for active booking
final activeBookingProvider = StreamProvider.autoDispose<Map<String, dynamic>?>((ref) async* {
  final user = ref.watch(authProvider).user;
  if (user == null) {
    yield null;
    return;
  }

  while (true) {
    try {
      final response = await ApiClient.get('/bookings/read.php?user_id=${user['user_id']}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final records = data['records'] as List<dynamic>;
        // Find the active booking
        final active = records.firstWhere(
          (b) => b['status'] == 'WAITING' || b['status'] == 'CALLED',
          orElse: () => null,
        );
        yield active;
      } else {
        yield null;
      }
      } catch (_) {
      yield null;
    }
    await Future.delayed(const Duration(seconds: 2)); // Poll every 2 seconds
  }
});

class LiveTrackingScreen extends ConsumerWidget {
  const LiveTrackingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen for status changes to play audio notification
    ref.listen<AsyncValue<Map<String, dynamic>?>>(activeBookingProvider, (previous, next) {
      if (previous?.value != null && next.value != null) {
        final prevStatus = previous!.value!['status'];
        final nextStatus = next.value!['status'];
        
        if (prevStatus == 'WAITING' && nextStatus == 'CALLED') {
          final player = AudioPlayer();
          player.play(UrlSource('https://actions.google.com/sounds/v1/alarms/beep_short.ogg'));
        }
      }
    });

    final bookingStream = ref.watch(activeBookingProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Live Tracking', style: TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Inter', fontSize: 18, color: AppColors.textPrimary)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 24),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
      ),
      body: bookingStream.when(
        data: (booking) {
          if (booking == null) {
            return const Center(
              child: Text('No active booking found. You can book a token from Home.', style: TextStyle(color: AppColors.textSecondary)),
            );
          }

          final isCalled = booking['status'] == 'CALLED';

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isCalled)
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.success.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.notifications_active_outlined, color: AppColors.success, size: 28),
                        const SizedBox(width: 16),
                        Expanded(
                          child: const Text(
                            'It is your turn! Please proceed to the counter.',
                            style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Professional Digital Boarding Pass
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 10)
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      // Top Half: Token Info
                      Container(
                        padding: const EdgeInsets.all(32.0),
                        decoration: BoxDecoration(
                          color: isCalled ? AppColors.success : AppColors.textPrimary,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('TOKEN NO.', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 12, letterSpacing: 1)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                                  child: Text(isCalled ? 'YOUR TURN' : 'WAITING', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 10, letterSpacing: 1)),
                                )
                              ],
                            ),
                            const SizedBox(height: 24),
                            Text(
                              booking['token_number'],
                              style: const TextStyle(color: Colors.white, fontSize: 72, fontWeight: FontWeight.w800, fontFamily: 'Inter', height: 1),
                            ),
                            const SizedBox(height: 32),
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildStat(context, '${booking['people_ahead']}', 'Ahead'),
                                  Container(width: 1, height: 40, color: Colors.white.withOpacity(0.2)),
                                  _buildStat(context, '${booking['estimated_waiting_time']}m', 'Wait'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Dotted Cut-Out Line
                      Stack(
                        children: [
                          Container(height: 1, color: Colors.transparent),
                          Positioned(
                            left: -10, top: -10,
                            child: Container(width: 20, height: 20, decoration: const BoxDecoration(color: AppColors.background, shape: BoxShape.circle, border: Border(right: BorderSide(color: AppColors.border)))),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              children: List.generate(
                                30,
                                (index) => Expanded(
                                  child: Container(
                                    height: 2,
                                    color: index % 2 == 0 ? AppColors.border : Colors.transparent,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            right: -10, top: -10,
                            child: Container(width: 20, height: 20, decoration: const BoxDecoration(color: AppColors.background, shape: BoxShape.circle, border: Border(left: BorderSide(color: AppColors.border)))),
                          ),
                        ],
                      ),
                      
                      // Bottom Half: QR Code
                      Container(
                        padding: const EdgeInsets.all(32),
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'SCAN AT COUNTER',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: QrImageView(
                                data: booking['qr_verification_id'] ?? 'invalid',
                                version: QrVersions.auto,
                                size: 160.0,
                                foregroundColor: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              booking['qr_verification_id'] ?? '',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 4,
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: AppColors.error))),
      ),
    );
  }

  Widget _buildStat(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700, fontFamily: 'Inter')),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontWeight: FontWeight.w500, fontSize: 12)),
      ],
    );
  }
}
