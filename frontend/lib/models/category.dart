class Category {
  final int? id;
  final String name;
  final String description;
  final String? imagePath;
  final DateTime createdAt;
  final DateTime updatedAt;

  Category({
    this.id,
    required this.name,
    required this.description,
    this.imagePath,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imagePath': imagePath,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    print('🔄 Parsing category from map: $map');
    try {
      final category = Category(
        id: map['id'],
        name: map['name'] ?? '',
        description: map['description'] ?? '',
        imagePath: map['imagePath'],
        createdAt: map['createdAt'] != null
            ? DateTime.parse(map['createdAt'])
            : DateTime.now(),
        updatedAt: map['updatedAt'] != null
            ? DateTime.parse(map['updatedAt'])
            : DateTime.now(),
      );
      print(
        '✅ Category parsed: ${category.name}, imagePath: ${category.imagePath}',
      );
      return category;
    } catch (e) {
      print('❌ Error parsing category: $e');
      rethrow;
    }
  }

  Category copyWith({
    int? id,
    String? name,
    String? description,
    String? imagePath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
