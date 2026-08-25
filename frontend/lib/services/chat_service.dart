import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatService {
  final String baseUrl = "http://localhost:3000/api/chat";
  //final String baseUrl = "http://10.0.2.2:3000/api/chat";

  Future<String> sendMessage(String message) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'message': message}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['reply'] ?? 'No response from AI.';
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['error'] ?? 'Failed to get AI response.');
    }
  }
}
