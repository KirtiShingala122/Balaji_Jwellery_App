import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/customer.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class CustomerService {
  late final String baseUrl;
  late final String fallbackUrl;

  CustomerService() {
    if (kIsWeb) {
      baseUrl = "http://localhost:3000/api/customers";
      fallbackUrl = "http://10.0.2.2:3000/api/customers";
    } else if (Platform.isAndroid) {
      baseUrl = "http://10.0.2.2:3000/api/customers";
      fallbackUrl = "http://localhost:3000/api/customers";
    } else {
      baseUrl = "http://localhost:3000/api/customers";
      fallbackUrl = "http://10.0.2.2:3000/api/customers";
    }
  }

  Future<List<Customer>> getAllCustomers() async {
    for (final url in [baseUrl, fallbackUrl]) {
      try {
        final res = await http.get(Uri.parse(url));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body) as List;
          return data.map((e) => Customer.fromMap(e)).toList();
        }
      } catch (_) {
        // try next
      }
    }
    throw Exception('Failed to load customers (all hosts tried)');
  }

  Future<List<Customer>> searchCustomers(String query) async {
    final encoded = Uri.encodeQueryComponent(query);
    for (final url in [baseUrl, fallbackUrl]) {
      try {
        final res = await http.get(Uri.parse('$url/search?q=$encoded'));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body) as List;
          return data.map((e) => Customer.fromMap(e)).toList();
        }
      } catch (_) {
        // try next
      }
    }
    return [];
  }

  Future<Customer?> getCustomerById(int id) async {
    for (final url in [baseUrl, fallbackUrl]) {
      try {
        final response = await http.get(Uri.parse("$url/$id"));
        if (response.statusCode == 200) {
          return Customer.fromMap(jsonDecode(response.body));
        }
      } catch (_) {
        // try next
      }
    }
    return null;
  }

  Future<void> addCustomer(Customer customer) async {
    final res = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': customer.name,
        'email': customer.email,
        'phoneNumber': customer.phoneNumber,
        'address': customer.address,
      }),
    );
    if (res.statusCode != 201) {
      throw Exception('Failed to add customer (${res.statusCode})');
    }
  }

  Future<void> updateCustomer(Customer customer) async {
    if (customer.id == null) throw Exception('Customer id is required');
    final res = await http.put(
      Uri.parse("$baseUrl/${customer.id}"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': customer.name,
        'email': customer.email,
        'phoneNumber': customer.phoneNumber,
        'address': customer.address,
      }),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to update customer (${res.statusCode})');
    }
  }

  Future<void> deleteCustomer(int id) async {
    final res = await http.delete(Uri.parse("$baseUrl/$id"));
    if (res.statusCode != 200) {
      throw Exception('Failed to delete customer (${res.statusCode})');
    }
  }
}
