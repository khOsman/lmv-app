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

class _LearnerListScreenState extends State<LearnerListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<Learner> _learners;
  late List<VerifyStatus> _tabs;
  String? _refreshError;

  @override
  void initState() {
    super.initState();
    _learners = widget.branch.learners;
    _tabs = _computeTabs();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<VerifyStatus> _computeTabs() {
    final hasDuplicates = _learners.any((l) => l.status == VerifyStatus.duplicate);
    return [
      VerifyStatus.pending,
      VerifyStatus.verified,
      if (hasDuplicates) VerifyStatus.duplicate,
    ];
  }

  void _syncTabsIfNeeded() {
    final newTabs = _computeTabs();
    if (newTabs.length == _tabs.length) {
      _tabs = newTabs;
      return;
    }
    final oldController = _tabController;
    _tabs = newTabs;
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: oldController.index.clamp(0, _tabs.length - 1),
    );
    oldController.dispose();
  }

  Future<void> _refresh() async {
    try {
      final branch = await LearnerService.instance.getBranch(widget.branch.id);
      if (!mounted) return;
      setState(() {
        _learners = branch.learners;
        _refreshError = null;
        _syncTabsIfNeeded();
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

  int _countFor(VerifyStatus status) => _learners.where((l) => l.status == status).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.branch.name),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [for (final status in _tabs) Tab(text: '${status.label} (${_countFor(status)})')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [for (final status in _tabs) _buildTab(status)],
      ),
    );
  }

  Widget _buildTab(VerifyStatus status) {
    final learners = _learners.where((l) => l.status == status).toList();
    return RefreshIndicator(
      onRefresh: _refresh,
      child: learners.isEmpty
          ? ListView(
              children: [
                const SizedBox(height: 80),
                if (_refreshError != null) ...[
                  Icon(Icons.error_outline, color: AppColors.red, size: 40),
                  const SizedBox(height: 12),
                  Center(child: Text(_refreshError!, textAlign: TextAlign.center)),
                ] else
                  Center(child: Text('No ${status.label.toLowerCase()} learners.')),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: learners.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) => _LearnerCard(
                learner: learners[index],
                onVerify: () => _onVerifyTap(learners[index]),
              ),
            ),
    );
  }
}

class _LearnerCard extends StatelessWidget {
  final Learner learner;
  final VoidCallback onVerify;

  const _LearnerCard({required this.learner, required this.onVerify});

  @override
  Widget build(BuildContext context) {
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
            if (learner.learnerCode.isNotEmpty)
              _InfoRow(icon: Icons.badge_outlined, text: 'Learner ID: ${learner.learnerCode}'),
            _InfoRow(icon: Icons.wc, text: learner.gender),
            _InfoRow(icon: Icons.phone_outlined, text: learner.phone),
            _InfoRow(icon: Icons.man_outlined, text: _labeled('Father', learner.fatherName)),
            _InfoRow(icon: Icons.woman_outlined, text: _labeled('Mother', learner.motherName)),
            _InfoRow(icon: Icons.home_outlined, text: learner.address),
            _InfoRow(icon: Icons.fact_check_outlined, text: 'Selection: ${learner.selection}'),
            if (learner.status == VerifyStatus.verified && learner.pvcCode != null)
              _InfoRow(icon: Icons.badge_outlined, text: 'PVC: ${learner.pvcCode}'),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: learner.status == VerifyStatus.verified ? null : onVerify,
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
  }

  static String _labeled(String label, String value) => value.isEmpty ? '' : '$label: $value';
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
