import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';

class QRScannerScreen extends ConsumerStatefulWidget {
  final String orgId;
  const QRScannerScreen({super.key, required this.orgId});

  @override
  ConsumerState<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends ConsumerState<QRScannerScreen> {
  bool _isProcessing = false;
  MobileScannerController cameraController = MobileScannerController();

  Future<void> _verifyTicket(String qrData) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final response = await ApiClient.post('/queues/verify.php', {
        'org_id': widget.orgId,
        'qr_data': qrData,
      });

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Ticket Verified Successfully!'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 3),
          ));
          context.pop(); // Go back to dashboard
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(jsonDecode(response.body)['message'] ?? 'Invalid Ticket'),
            backgroundColor: AppColors.error,
          ));
          // Wait a bit before allowing another scan
          await Future.delayed(const Duration(seconds: 3));
          setState(() => _isProcessing = false);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Network Error. Please try again.'),
          backgroundColor: AppColors.error,
        ));
        await Future.delayed(const Duration(seconds: 3));
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan Customer Ticket', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null && !_isProcessing) {
                  _verifyTicket(barcode.rawValue!);
                  break;
                }
              }
            },
          ),
          
          // Scanner Overlay Frame
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.success, width: 4),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          
          // Processing Indicator
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.success),
                    SizedBox(height: 16),
                    Text('Verifying...', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            
          // Bottom Instructions
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Text(
              'Position the customer\'s QR code in the frame',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16),
            ),
          )
        ],
      ),
    );
  }
}
