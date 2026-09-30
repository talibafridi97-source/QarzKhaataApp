/// Enum representing the transaction flow type.
/// [gave]: Shopkeeper gave credit / goods to debtor (increases amount owed by debtor).
/// [got]: Shopkeeper received payment / cash from debtor (decreases amount owed by debtor).
enum TransactionType { gave, got }

/// Model representing a ledger transaction for a specific debtor.
class TransactionModel {
  final int? id;
  final int debtorId;
  final String itemDetails;
  final double amount;
  final TransactionType type;
  final DateTime timestamp;
  final DateTime? dueDate;

  TransactionModel({
    this.id,
    required this.debtorId,
    required this.itemDetails,
    required this.amount,
    required this.type,
    required this.timestamp,
    this.dueDate,
  });

  /// Convert TransactionModel object to a Map for SQLite insertion/update.
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'debtor_id': debtorId,
      'item_details': itemDetails,
      'amount': amount,
      'type': type == TransactionType.gave ? 'GAVE' : 'GOT',
      'timestamp': timestamp.toIso8601String(),
      'due_date': dueDate?.toIso8601String(),
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  /// Create a TransactionModel object from a SQLite map representation.
  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as int?,
      debtorId: map['debtor_id'] as int,
      itemDetails: map['item_details'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: (map['type'] as String) == 'GAVE' ? TransactionType.gave : TransactionType.got,
      timestamp: DateTime.parse(map['timestamp'] as String),
      dueDate: map['due_date'] != null ? DateTime.parse(map['due_date'] as String) : null,
    );
  }

  /// Copy with helper for updating transaction fields.
  TransactionModel copyWith({
    int? id,
    int? debtorId,
    String? itemDetails,
    double? amount,
    TransactionType? type,
    DateTime? timestamp,
    DateTime? dueDate,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      debtorId: debtorId ?? this.debtorId,
      itemDetails: itemDetails ?? this.itemDetails,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      dueDate: dueDate ?? this.dueDate,
    );
  }

  /// Helper to check if this transaction increases debtor's debt.
  bool get isGave => type == TransactionType.gave;
}
