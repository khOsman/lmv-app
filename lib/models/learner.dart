enum VerifyStatus {
  pending,
  verified,
  duplicate;

  static VerifyStatus fromString(String? value) {
    switch ((value ?? '').toLowerCase()) {
      case 'verified':
        return VerifyStatus.verified;
      case 'duplicate':
        return VerifyStatus.duplicate;
      case 'pending':
      default:
        return VerifyStatus.pending;
    }
  }

  String get label {
    switch (this) {
      case VerifyStatus.verified:
        return 'Verified';
      case VerifyStatus.duplicate:
        return 'Duplicate';
      case VerifyStatus.pending:
        return 'Pending';
    }
  }
}

class Learner {
  final String id;
  final String learnerCode;
  final String name;
  final String gender;
  final String phone;
  final String maskedPhone;
  final String fatherName;
  final String motherName;
  final String address;
  final VerifyStatus status;
  final String? pvcCode;

  const Learner({
    required this.id,
    required this.learnerCode,
    required this.name,
    required this.gender,
    required this.phone,
    required this.maskedPhone,
    required this.fatherName,
    required this.motherName,
    required this.address,
    required this.status,
    this.pvcCode,
  });

  factory Learner.fromJson(Map<String, dynamic> json) {
    return Learner(
      id: json['learnerId'] as String,
      learnerCode: json['learnerCode'] as String? ?? '',
      name: json['name'] as String? ?? '',
      gender: json['gender'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      maskedPhone: json['maskedPhone'] as String? ?? '',
      fatherName: json['fatherName'] as String? ?? '',
      motherName: json['motherName'] as String? ?? '',
      address: json['address'] as String? ?? '',
      status: VerifyStatus.fromString(json['status'] as String?),
      pvcCode: json['pvcCode'] as String?,
    );
  }

  Learner copyWith({VerifyStatus? status, String? pvcCode}) {
    return Learner(
      id: id,
      learnerCode: learnerCode,
      name: name,
      gender: gender,
      phone: phone,
      maskedPhone: maskedPhone,
      fatherName: fatherName,
      motherName: motherName,
      address: address,
      status: status ?? this.status,
      pvcCode: pvcCode ?? this.pvcCode,
    );
  }
}
