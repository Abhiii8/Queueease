import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';

class CounterAgentScreen extends ConsumerStatefulWidget {
  final String serviceId;
  const CounterAgentScreen({super.key, required this.serviceId});

  @override
  ConsumerState<CounterAgentScreen> createState() => _CounterAgentScreenState();
}

class _CounterAgentScreenState extends ConsumerState<CounterAgentScreen> {
  bool _isLoading = false;
  String? _calledToken;

  Future<void> _callNext() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiClient.post('/queues/call_next.php', {
        'service_id': widget.serviceId
      });
      
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _calledToken = data['called_token'];
          });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Called Token: ${data['called_token']}', style: const TextStyle(fontWeight: FontWeight.w600)),
            backgroundColor: AppColors.success,
          ));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(data['message'] ?? 'Failed to call next token'),
            backgroundColor: AppColors.error,
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Network Error'),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Counter Panel', style: TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Inter', fontSize: 18, color: AppColors.textPrimary)),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Current Token Display
            if (_calledToken != null)
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: AppColors.success.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))
                  ],
                ),
                child: Column(
                  children: [
                    const Text('CURRENTLY CALLED', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                    const SizedBox(height: 8),
                    Text(_calledToken!, style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w800, fontFamily: 'Inter')),
                    const SizedBox(height: 8),
                    const Text('Waiting for customer to arrive at counter...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),

            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(Icons.record_voice_over_outlined, size: 40, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Call Next Customer',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Alert the next person in line that it is their turn.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500, fontSize: 13),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.textPrimary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _isLoading ? null : _callNext,
                      child: _isLoading 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Call Next Token', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(Icons.qr_code_scanner_rounded, size: 40, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Scan Arrival',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Scan the user\'s QR code when they arrive at the counter to verify.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500, fontSize: 13),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: _calledToken == null ? AppColors.textSecondary : AppColors.textPrimary,
                        elevation: 0,
                        side: BorderSide(color: _calledToken == null ? AppColors.border : AppColors.textPrimary, width: _calledToken == null ? 1 : 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        if (_calledToken == null) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text('Please Call Next Token first before scanning.'),
                            backgroundColor: AppColors.error,
                          ));
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Scanner Opening...')));
                        // TODO: Implement actual scanner navigation
                      },
                      child: Text('Scan QR Code', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _calledToken == null ? AppColors.textSecondary : AppColors.textPrimary)),
                    ),
                  ),
                  if (_calledToken == null)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Text('Requires calling a token first', style: TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.w500)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
