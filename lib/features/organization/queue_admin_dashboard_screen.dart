import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_provider.dart';

class QueueAdminDashboardScreen extends ConsumerStatefulWidget {
  final String orgId;
  const QueueAdminDashboardScreen({super.key, required this.orgId});

  @override
  ConsumerState<QueueAdminDashboardScreen> createState() => _QueueAdminDashboardScreenState();
}

class _QueueAdminDashboardScreenState extends ConsumerState<QueueAdminDashboardScreen> {
  Timer? _timer;
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _queueData;
  bool _isAdvancing = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _fetchData());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      final response = await ApiClient.get('/organizations/admin_queue.php?org_id=${widget.orgId}');
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _queueData = jsonDecode(response.body);
            _isLoading = false;
            _error = null;
          });
        }
      } else if (response.statusCode == 404) {
        if (mounted) {
          setState(() {
            _error = 'No active queue found for today.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted && _queueData == null) {
        setState(() {
          _error = 'Network error: Unable to load queue.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _advanceQueue(String queueId, String action) async {
    if (_isAdvancing) return;
    setState(() => _isAdvancing = true);
    
    try {
      final response = await ApiClient.post('/queues/advance.php', {
        'queue_id': queueId,
        'action': action,
      });
      if (response.statusCode == 200) {
        await _fetchData(); // Instantly refresh
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Called Next Token!'), backgroundColor: AppColors.success)
          );
        }
      } else {
        if (mounted) {
          final data = jsonDecode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'Failed to advance queue'), backgroundColor: AppColors.warning)
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Network error.'), backgroundColor: AppColors.error)
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAdvancing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Live Queue Dashboard')),
      body: SafeArea(
        child: _buildBody(isDark),
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: AppColors.error),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 16)),
          ],
        ),
      );
    }

    if (_queueData == null) {
      return const Center(child: Text('Unexpected error.'));
    }

    final queue = _queueData!['queue'];
    final waitingList = _queueData!['waiting_list'] as List;

    return Column(
      children: [
        // Dashboard Header
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 30, offset: const Offset(0, 15))
            ]
          ),
          child: Column(
            children: [
              Text(
                queue['service_name'] ?? 'Queue',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, color: const Color(0xFF0F172A))
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(child: _buildStatCard(context, 'Serving Now', '${queue['token_prefix']}-${queue['current_token_number']}', AppColors.primary)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildStatCard(context, 'Waiting', '${queue['total_waiting']}', AppColors.warning)),
                ],
              ),
              const SizedBox(height: 32),
              Container(
                height: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.success, Color(0xFF10B981)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: AppColors.success.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: (waitingList.isEmpty || _isAdvancing) ? null : () => _advanceQueue(queue['queue_id'].toString(), 'CALL_NEXT'),
                  icon: _isAdvancing 
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.campaign, size: 28, color: Colors.white),
                  label: Text(_isAdvancing ? 'CALLING...' : 'CALL NEXT TOKEN', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: OutlinedButton.icon(
                  onPressed: () {
                    context.push('/scan_qr/${widget.orgId}');
                  },
                  icon: const Icon(Icons.qr_code_scanner, size: 28),
                  label: const Text('SCAN TICKET (COUNTER)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF64748B),
                    side: const BorderSide(color: Color(0xFFE2E8F0), width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Waiting List
        Expanded(
          child: waitingList.isEmpty
              ? const Center(child: Text('No customers waiting.', style: TextStyle(color: Color(0xFF64748B))))
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: waitingList.length,
                  itemBuilder: (context, index) {
                    final waiter = waitingList[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))
                        ],
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              waiter['token_number'].toString().split('-').last,
                              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 18)
                            ),
                          ),
                        ),
                        title: Text(waiter['token_number'], style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A), fontSize: 18)),
                        subtitle: Text(waiter['user_name'] ?? 'Guest', style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text('WAITING', style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1)),
                        ),
                      ),
                    );
                  },
                ),
        )
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
          const SizedBox(height: 8),
          Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: color, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}
