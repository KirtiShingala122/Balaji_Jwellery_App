class Bill {
  final int? id;
  final String billNumber;
  final int customerId;
  final double subtotal;
  final double taxAmount;
  final double discountAmount;
  final double totalAmount;
  final DateTime billDate;
  final String paymentStatus;
  final String? notes;
  final DateTime createdAt;

  Bill({
    this.id,
    required this.billNumber,
    required this.customerId,
    required this.subtotal,
    required this.taxAmount,
    required this.discountAmount,
    required this.totalAmount,
    required this.billDate,
    required this.paymentStatus,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'billNumber': billNumber,
      'customerId': customerId,
      'subtotal': subtotal,
      'taxAmount': taxAmount,
      'discountAmount': discountAmount,
      'totalAmount': totalAmount,
      'billDate': billDate.toIso8601String(),
      'paymentStatus': paymentStatus,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Bill.fromMap(Map<String, dynamic> map) {
    return Bill(
      id: map['id'],
      billNumber: map['billNumber'] ?? '',
      customerId: map['customerId'] ?? 0,
      subtotal: _toDouble(map['subtotal']),
      taxAmount: _toDouble(map['taxAmount']),
      discountAmount: _toDouble(map['discountAmount']),
      totalAmount: _toDouble(map['totalAmount']),
      billDate: _toDate(map['billDate']),
      paymentStatus: map['paymentStatus'] ?? 'pending',
      notes: map['notes'],
      createdAt: _toDate(map['createdAt']),
    );
  }

  Bill copyWith({
    int? id,
    String? billNumber,
    int? customerId,
    double? subtotal,
    double? taxAmount,
    double? discountAmount,
    double? totalAmount,
    DateTime? billDate,
    String? paymentStatus,
    String? notes,
    DateTime? createdAt,
  }) {
    return Bill(
      id: id ?? this.id,
      billNumber: billNumber ?? this.billNumber,
      customerId: customerId ?? this.customerId,
      subtotal: subtotal ?? this.subtotal,
      taxAmount: taxAmount ?? this.taxAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      billDate: billDate ?? this.billDate,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0.0;
}

DateTime _toDate(dynamic value) {
  if (value == null) return DateTime.now();
  return DateTime.tryParse(value.toString()) ?? DateTime.now();
}

int _toInt(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

class BillItem {
  final int? id;
  final int billId;
  final int productId;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  BillItem({
    this.id,
    required this.billId,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'billId': billId,
      'productId': productId,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
    };
  }

  factory BillItem.fromMap(Map<String, dynamic> map) {
    return BillItem(
      id: map['id'],
      billId: map['billId'] ?? 0,
      productId: map['productId'] ?? 0,
      quantity: _toInt(map['quantity']),
      unitPrice: _toDouble(map['unitPrice']),
      totalPrice: _toDouble(map['totalPrice']),
    );
  }
}
