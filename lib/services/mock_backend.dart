import 'dart:math';

import '../models/branch.dart';
import '../models/learner.dart';
import '../models/verify_result.dart';
import 'api_exception.dart';

/// Stands in for the real backend during UI development. Holds the sample
/// payload in memory (mutated in place as learners get verified) so the
/// app behaves like a live backend for demo/testing purposes.
class MockBackend {
  MockBackend._();

  static final MockBackend instance = MockBackend._();

  static const dummyOtp = '123456';

  final List<Map<String, dynamic>> _branches = [
    {
      "branchId": "BR-001",
      "branchName": "BISD Dhaka",
      "learners": [
        {
          "learnerId": "L-1001",
          "name": "Md. Osman Haruni",
          "gender": "Male",
          "phone": "+8801929647520",
          "maskedPhone": "**** **** 9869",
          "status": "pending",
          "pvcCode": null,
        },
        {
          "learnerId": "L-1002",
          "name": "Nusrat Jahan",
          "gender": "Female",
          "phone": "+8801712345678",
          "maskedPhone": "**** **** 5678",
          "status": "verified",
          "pvcCode": "PVC458",
        },
        {
          "learnerId": "L-2001",
          "name": "Sajib Ahmed",
          "gender": "Male",
          "phone": "+8801811122233",
          "maskedPhone": "**** **** 2233",
          "status": "duplicate",
          "pvcCode": null,
        },
        {
          "learnerId": "L-2002",
          "name": "Tasdid Rahman",
          "gender": "Male",
          "phone": "+8801730346655",
          "maskedPhone": "**** **** 8776",
          "status": "pending",
          "pvcCode": null,
        },
      ],
    },
    {
      "branchId": "BR-002",
      "branchName": "BISD Gazipur",
      "learners": [
        {
          "learnerId": "L-2001",
          "name": "Sajib Ahmed",
          "gender": "Male",
          "phone": "+8801811122233",
          "maskedPhone": "**** **** 2233",
          "status": "duplicate",
          "pvcCode": null,
        },
        {
          "learnerId": "L-2002",
          "name": "Farzana Rahman",
          "gender": "Female",
          "phone": "+8801919988776",
          "maskedPhone": "**** **** 8776",
          "status": "pending",
          "pvcCode": null,
        },
      ],
    },
  ];

  Future<List<Branch>> getBranches() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _branches.map((b) => Branch.fromJson(b)).toList();
  }

  Future<void> sendOtp(String learnerId) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<VerifyResult> verifyOtp(String learnerId, String otp) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (otp.trim() != dummyOtp) {
      throw const ApiException('Invalid OTP. Use $dummyOtp for the demo.');
    }

    final pvcCode = _generatePvcCode();

    for (final branch in _branches) {
      for (final learner in (branch['learners'] as List<dynamic>)) {
        if (learner['learnerId'] == learnerId) {
          learner['status'] = 'verified';
          learner['pvcCode'] = pvcCode;
        }
      }
    }

    return (status: VerifyStatus.verified, pvcCode: pvcCode);
  }

  String _generatePvcCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    return List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
  }
}
