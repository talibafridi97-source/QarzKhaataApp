/// Model representing a Debtor (Kharzdaar) in the Khata application.
class Debtor {
  final int? id;
  final String name;
  final String phone;
  final DateTime createdAt;
  final double netBalance;

  Debtor({
    this.id,
    required this.name,
    required this.phone,
    required this.createdAt,
    this.netBalance = 0.0,
  });

  /// Convert Debtor object to a Map for SQLite insertion/update.
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'phone': phone,
      'created_at': createdAt.toIso8601String(),
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  /// Create a Debtor object from a SQLite map representation.
  factory Debtor.fromMap(Map<String, dynamic> map, {double? calculatedNetBalance}) {
    return Debtor(
      id: map['id'] as int?,
      name: map['name'] as String,
      phone: map['phone'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      netBalance: calculatedNetBalance ?? (map['net_balance'] != null ? (map['net_balance'] as num).toDouble() : 0.0),
    );
  }

  /// Copy with helper for immutability updates.
  Debtor copyWith({
    int? id,
    String? name,
    String? phone,
    DateTime? createdAt,
    double? netBalance,
  }) {
    return Debtor(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      createdAt: createdAt ?? this.createdAt,
      netBalance: netBalance ?? this.netBalance,
    );
  }
}
