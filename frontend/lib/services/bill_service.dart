import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../models/bill.dart';

class BillRecord {
  final Bill bill;
  final String customerName;
  BillRecord({required this.bill, required this.customerName});
}

class BillDetail {
  final Bill bill;
  final List<BillItem> items;
  BillDetail({required this.bill, required this.items});
}

class BillService {
  late final String baseUrl;

  BillService() {
    if (kIsWeb) {
      baseUrl = "http://localhost:3000/api/bills";
    } else if (Platform.isAndroid) {
      baseUrl = "http://10.0.2.2:3000/api/bills";
    } else {
      baseUrl = "http://localhost:3000/api/bills";
    }
  }

  Future<List<BillRecord>> getBills() async {
    final res = await http.get(Uri.parse(baseUrl));
    if (res.statusCode != 200) {
      throw Exception('Failed to load bills (${res.statusCode})');
    }
    final data = jsonDecode(res.body) as List<dynamic>;
    return data
        .map(
          (e) => BillRecord(
            bill: Bill.fromMap(e as Map<String, dynamic>),
            customerName: (e)['customerName'] ?? '',
          ),
        )
        .toList();
  }

  Future<BillDetail?> getBillWithItems(int id) async {
    final res = await http.get(Uri.parse('$baseUrl/$id'));
    if (res.statusCode == 404) return null;
    if (res.statusCode != 200) {
      throw Exception('Failed to fetch bill (${res.statusCode})');
    }
    final map = jsonDecode(res.body) as Map<String, dynamic>;
    final itemsRaw = (map['items'] as List<dynamic>? ?? []);
    return BillDetail(
      bill: Bill.fromMap(map),
      items: itemsRaw
          .map((e) => BillItem.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<Map<String, dynamic>> addBill({
    required int customerId,
    required double taxAmount,
    required double discountAmount,
    required String paymentStatus,
    String? notes,
    required List<Map<String, dynamic>> items,
  }) async {
    final res = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'customerId': customerId,
        'taxAmount': taxAmount,
        'discountAmount': discountAmount,
        'paymentStatus': paymentStatus,
        'notes': notes,
        'items': items,
      }),
    );

    if (res.statusCode != 201) {
      throw Exception('Failed to add bill (${res.statusCode})');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<void> deleteBill(int id) async {
    final res = await http.delete(Uri.parse('$baseUrl/$id'));
    if (res.statusCode != 200) {
      throw Exception('Failed to delete bill (${res.statusCode})');
    }
  }
}
