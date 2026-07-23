import 'learner.dart';

class Branch {
  final String id;
  final String name;
  final List<Learner> learners;

  const Branch({required this.id, required this.name, this.learners = const []});

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json['branchId'] as String,
      name: json['branchName'] as String,
      learners: (json['learners'] as List? ?? [])
          .map((e) => Learner.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Branch copyWith({List<Learner>? learners}) {
    return Branch(id: id, name: name, learners: learners ?? this.learners);
  }
}
