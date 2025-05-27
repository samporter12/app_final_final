class UserProfileModel {
  String? id;
  final String userId;
  String name;
  int? age;
  double? weight;
  String goal;
  String fitnessLevel;
  DateTime? createdAt;
  DateTime? updatedAt;

  UserProfileModel({
    this.id,
    required this.userId,
    required this.name,
    this.age,
    this.weight,
    required this.goal,
    required this.fitnessLevel,
    this.createdAt,
    this.updatedAt,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['\$id'] as String?,
      userId: json['userId'] as String,
      name: json['name'] as String? ?? '',
      age: json['age'] as int?,
      weight: (json['weight'] as num?)?.toDouble(),
      goal: json['goal'] as String,
      fitnessLevel: json['fitnessLevel'] as String,
      createdAt:
          json['\$createdAt'] != null
              ? DateTime.tryParse(json['\$createdAt'])
              : null,
      updatedAt:
          json['\$updatedAt'] != null
              ? DateTime.tryParse(json['\$updatedAt'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'age': age,
      'weight': weight,
      'goal': goal,
      'fitnessLevel': fitnessLevel,
    };
  }
}
