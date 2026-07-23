import 'package:flutter/material.dart';

import '../models/branch.dart';
import '../models/learner.dart';
import '../services/api_exception.dart';
import '../services/learner_service.dart';
import '../theme/app_colors.dart';
import '../widgets/status_chip.dart';
import 'verify_otp_sheet.dart';

class LearnerListScreen extends StatefulWidget {
  final Branch branch;

  const LearnerListScreen({super.key, required this.branch});

  @override
  State<LearnerListScreen> createState() => _LearnerListScreenState();
}

class _LearnerListScreenState extends State<LearnerListScreen> {
  late List<Learner> _learners;
  String? _refreshError;

  @override
  void initState() {
    super.initState();
    _learners = widget.branch.learners;
  }

  Future<void> _refresh() async {
    try {
      final branch = await LearnerService.instance.getBranch(widget.branch.id);
      if (!mounted) return;
      setState(() {
        _learners = branch.learners;
        _refreshError = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _refreshError = e.message);
    }
  }

  Future<void> _onVerifyTap(Learner learner) async {
    final result = await showVerifyOtpSheet(context, learner);
    if (result == null) return;
    setState(() {
      _learners = [
        for (final l in _learners)
          if (l.id == learner.id) l.copyWith(status: result.status, pvcCode: result.pvcCode) else l,
      ];
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${learner.name} marked as ${result.status.label}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.branch.name)),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _learners.isEmpty
            ? ListView(
                children: [
                  const SizedBox(height: 80),
                  if (_refreshError != null) ...[
                    Icon(Icons.error_outline, color: AppColors.red, size: 40),
                    const SizedBox(height: 12),
                    Center(child: Text(_refreshError!, textAlign: TextAlign.center)),
                  ] else
                    const Center(child: Text('No learners found for this branch.')),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _learners.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final learner = _learners[index];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  learner.name,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                ),
                              ),
                              StatusChip(status: learner.status),
                            ],
                          ),
                          const SizedBox(height: 6),
                          _InfoRow(icon: Icons.wc, text: learner.gender),
                          _InfoRow(icon: Icons.phone_outlined, text: learner.maskedPhone),
                          if (learner.status == VerifyStatus.verified && learner.pvcCode != null)
                            _InfoRow(icon: Icons.badge_outlined, text: 'PVC: ${learner.pvcCode}'),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: OutlinedButton.icon(
                              onPressed: learner.status == VerifyStatus.verified
                                  ? null
                                  : () => _onVerifyTap(learner),
                              icon: const Icon(Icons.sms_outlined, size: 18),
                              label: const Text('Verify'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.magenta,
                                side: const BorderSide(color: AppColors.magenta),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppColors.coolGray),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: TextStyle(color: AppColors.coolGray, fontSize: 13))),
        ],
      ),
    );
  }
}
