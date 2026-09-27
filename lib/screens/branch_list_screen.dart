import 'package:flutter/material.dart';

import '../models/branch.dart';
import '../models/learner.dart';
import '../services/api_exception.dart';
import '../services/auth_service.dart';
import '../services/learner_service.dart';
import '../theme/app_colors.dart';
import 'learner_list_screen.dart';
import 'login_screen.dart';

class BranchListScreen extends StatefulWidget {
  const BranchListScreen({super.key});

  @override
  State<BranchListScreen> createState() => _BranchListScreenState();
}

class _BranchListScreenState extends State<BranchListScreen> {
  late Future<List<Branch>> _branchesFuture;
  String? _dmName;
  String? _dmUsername;

  @override
  void initState() {
    super.initState();
    _branchesFuture = LearnerService.instance.getBranches();
    AuthService.instance.getDmName().then((name) {
      if (mounted) setState(() => _dmName = name);
    });
    AuthService.instance.getDmUsername().then((username) {
      if (mounted) setState(() => _dmUsername = username);
    });
  }

  Future<void> _refresh() async {
    setState(() {
      _branchesFuture = LearnerService.instance.getBranches();
    });
    await _branchesFuture;
  }

  Future<void> _logout() async {
    await AuthService.instance.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_dmName ?? 'My Branches'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Account',
            icon: const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white24,
              child: Icon(Icons.person, color: Colors.white, size: 20),
            ),
            onSelected: (value) {
              if (value == 'logout') _logout();
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _dmName ?? 'DM',
                      style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.neutralBlack),
                    ),
                    if (_dmUsername != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        _dmUsername!,
                        style: TextStyle(fontSize: 12, color: AppColors.coolGray),
                      ),
                    ],
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 18, color: AppColors.red),
                    SizedBox(width: 10),
                    Text('Log out', style: TextStyle(color: AppColors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Branch>>(
          future: _branchesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              final message = snapshot.error is ApiException
                  ? (snapshot.error as ApiException).message
                  : 'Something went wrong.';
              return ListView(
                children: [
                  const SizedBox(height: 80),
                  Icon(Icons.error_outline, color: AppColors.red, size: 40),
                  const SizedBox(height: 12),
                  Center(child: Text(message, textAlign: TextAlign.center)),
                ],
              );
            }
            final branches = snapshot.data ?? [];
            if (branches.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 80),
                  Center(child: Text('No branches assigned to your account.')),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: branches.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final branch = branches[index];
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.magenta,
                      child: Icon(Icons.apartment, color: Colors.white),
                    ),
                    title: Text(branch.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(_learnerSummary(branch)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => LearnerListScreen(branch: branch),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  String _learnerSummary(Branch branch) {
    final total = branch.learners.length;
    final verified = branch.learners.where((l) => l.status == VerifyStatus.verified).length;
    return '$total learner${total == 1 ? '' : 's'} · $verified verified';
  }
}
