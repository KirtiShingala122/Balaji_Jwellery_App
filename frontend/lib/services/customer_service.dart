import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/customer.dart';

class CustomerService {
  final String baseUrl = "http://localhost:3000/api/customers";
   //final String baseUrl = "http://10.0.2.2:3000/api/customers";
  Future<Customer?> getCustomerById(int id) async {
    final response = await http.get(Uri.parse("$baseUrl/$id"));
    if (response.statusCode == 200) {
      return Customer.fromMap(jsonDecode(response.body));
    }
    return null;
  }
}
