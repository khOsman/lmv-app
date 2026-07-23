import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../services/api_exception.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import 'branch_list_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthService.instance.login();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const BranchListScreen()),
      );
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: AppColors.magenta,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.verified_user, color: Colors.white, size: 36),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'DM Login',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.neutralBlack),
                ),
                const SizedBox(height: 4),
                Text(
                  'Learner Mobile Verification',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: AppColors.coolGray),
                ),
                const SizedBox(height: 8),
                Text(
                  "You'll log in with your Salesforce account on Salesforce's own login page.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppColors.coolGray),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 20),
                  Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.red, fontSize: 13)),
                ],
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _loading ? null : _login,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Log In with Salesforce'),
                ),
                if (ApiConfig.useMockData) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.skyBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.skyBlue.withValues(alpha: 0.4)),
                    ),
                    child: const Text(
                      'Demo mode: tap to log in instantly with sample data. '
                      'Use OTP 123456 to verify a learner.',
                      style: TextStyle(fontSize: 12, color: AppColors.coolGray),
                    ),
                  ),
                ],
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
