/// Model representing an authenticated App User stored locally in SQLite.
class UserModel {
  final int? id;
  final String name;
  final String email;
  final String? imagePath;
  final DateTime createdAt;

  UserModel({
    this.id,
    required this.name,
    required this.email,
    this.imagePath,
    required this.createdAt,
  });

  /// Convert UserModel to Map for SQLite storage
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'email': email,
      'image_path': imagePath,
      'created_at': createdAt.toIso8601String(),
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  /// Create UserModel from SQLite map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      email: map['email'] as String,
      imagePath: map['image_path'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Copy with helper
  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? imagePath,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
