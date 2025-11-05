class Product {
  final int? id;
  final String uniqueCode;
  final String name;
  final String description;
  final int categoryId;
  final double price;
  final int stockQuantity;
  final String? imagePath;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    this.id,
    required this.uniqueCode,
    required this.name,
    required this.description,
    required this.categoryId,
    required this.price,
    required this.stockQuantity,
    this.imagePath,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uniqueCode': uniqueCode,
      'name': name,
      'description': description,
      'categoryId': categoryId,
      'price': price,
      'stockQuantity': stockQuantity,
      'imagePath': imagePath,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      uniqueCode: map['uniqueCode'],
      name: map['name'],
      description: map['description'],
      categoryId: map['categoryId'],
      price: map['price'].toDouble(),
      stockQuantity: map['stockQuantity'],
      imagePath: map['imagePath'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  Product copyWith({
    int? id,
    String? uniqueCode,
    String? name,
    String? description,
    int? categoryId,
    double? price,
    int? stockQuantity,
    String? imagePath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      uniqueCode: uniqueCode ?? this.uniqueCode,
      name: name ?? this.name,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      price: price ?? this.price,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isLowStock => stockQuantity <= 5;
}
