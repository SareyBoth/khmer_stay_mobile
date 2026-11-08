import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_state.dart';
import '../../core/api/api_client.dart';
import '../startup/startup_screens.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key, required this.bookingId});
  final String bookingId;

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  Map<String, dynamic>? payment;
  String? error;
  bool busy = false;
  bool _paymentConfirmed = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(load);
  }

  Future<void> _triggerPaymentConfirmed() async {
    if (_paymentConfirmed) return;
    if (mounted) {
      setState(() {
        _paymentConfirmed = true;
        error = null;
      });
    }
    await ref.read(appControllerProvider.notifier).loadServerData();
    await Future<void>.delayed(const Duration(milliseconds: 1800));
    if (mounted) {
      context.go('/booking-success/${widget.bookingId}');
    }
  }

  Future<void> load() async {
    try {
      final result = await ref
          .read(apiClientProvider)
          .request('/bookings/${widget.bookingId}/payment');
      if (mounted) {
        setState(() {
          payment = result;
          error = null;
        });
        if (result['status'] == 'Paid') {
          _triggerPaymentConfirmed();
        }
      }
    } catch (cause) {
      if (mounted) setState(() => error = cause.toString());
    }
  }

  Future<void> action(String path) async {
    setState(() => busy = true);
    try {
      final result = await ref
          .read(apiClientProvider)
          .request(path, method: 'POST');
      if (!mounted) return;
      setState(() => payment = result);
      if (result['status'] == 'Paid') {
        await _triggerPaymentConfirmed();
      }
    } catch (cause) {
      if (mounted) setState(() => error = cause.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget _buildSuccessAnimation() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 650),
      curve: Curves.elasticOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.green.shade400, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withValues(alpha: 0.18),
                  blurRadius: 24,
                  spreadRadius: 4,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 92,
                  height: 92,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 56,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  localized(
                    context,
                    'Payment Confirmed!',
                    'ការទូទាត់ត្រូវបានបញ្ជាក់!',
                  ),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  localized(
                    context,
                    'Bakong KHQR payment successfully verified.\nFinalizing your booking...',
                    'ការទូទាត់ Bakong KHQR ត្រូវបានផ្ទៀងផ្ទាត់ដោយជោគជ័យ។\nកំពុងបញ្ចប់ការកក់របស់អ្នក...',
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.green.shade900, height: 1.4),
                ),
                const SizedBox(height: 20),
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(lastPaidBookingIdProvider, (prev, next) {
      if (next == widget.bookingId && !_paymentConfirmed) {
        _triggerPaymentConfirmed();
      }
    });

    final data = payment;
    final token = ref.read(apiClientProvider).token;
    final configured = data?['configured'] == true;
    return Scaffold(
      appBar: AppBar(title: Text(localized(context, 'Payment', 'ការទូទាត់'))),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: _paymentConfirmed
                  ? _buildSuccessAnimation()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                  Text(
                    localized(
                      context,
                      'Complete your booking',
                      'បញ្ចប់ការកក់របស់អ្នក',
                    ),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  if (data == null && error == null)
                    const Center(child: CircularProgressIndicator()),
                  if (data != null) ...[
                    Text('USD \$${data['amount']} · ${data['status']}'),
                    const SizedBox(height: 24),
                    if (configured &&
                        (data['qrPayload'] as String).isNotEmpty) ...[
                      Center(
                        child: Image.network(
                          '$apiBaseUrl/bookings/${widget.bookingId}/payment/qr.png',
                          headers: {'Authorization': 'Bearer $token'},
                          width: 300,
                          height: 300,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SelectableText(data['qrPayload'] as String, maxLines: 2),
                      Text(
                        localized(
                          context,
                          'Scan with a KHQR supported banking app. Your booking is confirmed only after Bakong verifies the payment.',
                          'ស្កេនដោយកម្មវិធីធនាគារដែលគាំទ្រ KHQR។ ការកក់នឹងបញ្ជាក់ក្រោយពេលបាគងផ្ទៀងផ្ទាត់។',
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: busy
                            ? null
                            : () => action(
                                '/bookings/${widget.bookingId}/payment/check',
                              ),
                        child: Text(
                          localized(
                            context,
                            'Check payment',
                            'ពិនិត្យការទូទាត់',
                          ),
                        ),
                      ),
                    ] else ...[
                      Text(
                        localized(
                          context,
                          'KHQR payment is unavailable until the server has a Bakong receiving account and API token. No booking will be marked paid without Bakong verification.',
                          'ការទូទាត់ KHQR មិនអាចប្រើបានទេ រហូតដល់ម៉ាស៊ីនមេមានគណនីបាគងទទួលប្រាក់ និង API token។ ការកក់នឹងមិនត្រូវបានសម្គាល់ថាបានបង់ទេ បើគ្មានការផ្ទៀងផ្ទាត់ពីបាគង។',
                        ),
                      ),
                    ],
                  ],
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        error!,
                        style: const TextStyle(color: Colors.red),
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
}
