class Product {
  final int? id;
  final String uniqueCode;
  final String name;
  final String description;
  final int categoryId;
  final String? categoryName;
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
    this.categoryName,
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
      'categoryName': categoryName,
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
      uniqueCode: map['uniqueCode'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      categoryId: map['categoryId'] ?? 0,
      categoryName: map['categoryName'],

      // ✅ Safe parsing for price (handles string or number)
      price: map['price'] is num
          ? (map['price'] as num).toDouble()
          : double.tryParse(map['price'].toString()) ?? 0.0,

      // ✅ Safe parsing for stockQuantity
      stockQuantity: map['stockQuantity'] is num
          ? (map['stockQuantity'] as num).toInt()
          : int.tryParse(map['stockQuantity'].toString()) ?? 0,

      imagePath: map['imagePath'],

      // ✅ Parse createdAt / updatedAt safely
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
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
    String? categoryName,
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
      categoryName: categoryName ?? this.categoryName,
      price: price ?? this.price,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isLowStock => stockQuantity <= 5;
}
