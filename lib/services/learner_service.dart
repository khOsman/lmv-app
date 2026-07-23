import '../config/api_config.dart';
import '../models/branch.dart';
import '../models/learner.dart';
import '../models/verify_result.dart';
import 'api_client.dart';
import 'api_exception.dart';
import 'mock_backend.dart';

export '../models/verify_result.dart';

class LearnerService {
  LearnerService._();

  static final LearnerService instance = LearnerService._();

  final _client = ApiClient.instance;

  /// GET /branches -> branches assigned to the logged-in DM, each with its
  /// learners embedded (see the branch/learner JSON contract).
  Future<List<Branch>> getBranches() async {
    if (ApiConfig.useMockData) return MockBackend.instance.getBranches();
    final data = await _client.get('/branches') as List;
    return data.map((e) => Branch.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Re-fetches all branches and returns the one matching [branchId], used
  /// to refresh a single branch's learner list after a pull-to-refresh.
  Future<Branch> getBranch(String branchId) async {
    final branches = await getBranches();
    return branches.firstWhere(
      (b) => b.id == branchId,
      orElse: () => throw const ApiException('Branch not found.'),
    );
  }

  /// POST /learners/:id/send-otp -> triggers the SMS gateway
  Future<void> sendOtp(String learnerId) async {
    if (ApiConfig.useMockData) return MockBackend.instance.sendOtp(learnerId);
    await _client.post('/learners/$learnerId/send-otp');
  }

  /// POST /learners/:id/verify-otp { otp } -> updates Salesforce on match
  /// and returns the new status plus the issued (permanent) PVC code.
  Future<VerifyResult> verifyOtp(String learnerId, String otp) async {
    if (ApiConfig.useMockData) return MockBackend.instance.verifyOtp(learnerId, otp);
    final data = await _client.post('/learners/$learnerId/verify-otp', body: {'otp': otp}) as Map;
    return (
      status: VerifyStatus.fromString(data['status'] as String? ?? 'verified'),
      pvcCode: data['pvcCode'] as String?,
    );
  }
}
