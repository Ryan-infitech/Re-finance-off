class Transaction {
  final int? id;
  final String type; // 'income' or 'expense'
  final double amount;
  final String category;
  final String description;
  final String? imagePath;
  final String date;
  final String createdAt;

  Transaction({
    this.id,
    required this.type,
    required this.amount,
    required this.category,
    required this.description,
    this.imagePath,
    required this.date,
    required this.createdAt,
  });

  // Convert Transaction object to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'category': category,
      'description': description,
      'image_path': imagePath,
      'date': date,
      'created_at': createdAt,
    };
  }

  // Create Transaction object from Map
  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      type: map['type'],
      amount: map['amount'],
      category: map['category'],
      description: map['description'],
      imagePath: map['image_path'],
      date: map['date'],
      createdAt: map['created_at'],
    );
  }

  // Copy with method for updating transaction
  Transaction copyWith({
    int? id,
    String? type,
    double? amount,
    String? category,
    String? description,
    String? imagePath,
    String? date,
    String? createdAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
