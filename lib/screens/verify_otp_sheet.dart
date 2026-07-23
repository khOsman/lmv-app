import 'package:flutter/material.dart';

import '../models/learner.dart';
import '../services/api_exception.dart';
import '../services/learner_service.dart';
import '../theme/app_colors.dart';

/// Shows the OTP verification flow for [learner] as a modal bottom sheet.
/// Returns the [VerifyResult] if verification succeeded, or null if the
/// sheet was dismissed without a successful verification.
Future<VerifyResult?> showVerifyOtpSheet(BuildContext context, Learner learner) {
  return showModalBottomSheet<VerifyResult>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _VerifyOtpSheet(learner: learner),
  );
}

class _VerifyOtpSheet extends StatefulWidget {
  final Learner learner;

  const _VerifyOtpSheet({required this.learner});

  @override
  State<_VerifyOtpSheet> createState() => _VerifyOtpSheetState();
}

class _VerifyOtpSheetState extends State<_VerifyOtpSheet> {
  final _otpController = TextEditingController();
  bool _otpSent = false;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _sendOtp();
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await LearnerService.instance.sendOtp(widget.learner.id);
      if (!mounted) return;
      setState(() => _otpSent = true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.trim().isEmpty) {
      setState(() => _error = 'Enter the OTP sent to the learner.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await LearnerService.instance.verifyOtp(
        widget.learner.id,
        _otpController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(result);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
            ),
          ),
          const SizedBox(height: 20),
          Text('Verify ${widget.learner.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            'OTP will be sent to ${widget.learner.maskedPhone}',
            style: TextStyle(color: AppColors.coolGray, fontSize: 13),
          ),
          const SizedBox(height: 20),
          if (!_otpSent && _loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_otpSent) ...[
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Enter OTP',
                counterText: '',
                prefixIcon: Icon(Icons.sms_outlined),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _loading ? null : _sendOtp,
                child: const Text('Resend OTP'),
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 4),
            Text(_error!, style: const TextStyle(color: AppColors.red, fontSize: 13)),
          ],
          const SizedBox(height: 12),
          if (_otpSent)
            ElevatedButton(
              onPressed: _loading ? null : _verifyOtp,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Confirm'),
            ),
        ],
      ),
    );
  }
}
