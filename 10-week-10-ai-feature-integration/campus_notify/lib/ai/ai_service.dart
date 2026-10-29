import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AiService {
  final _storage = const FlutterSecureStorage();

  // Model resmi terbaru sesuai instruksi Google AI Studio
  static const String _model = 'models/gemini-3.8-flash';
  final _apiUrl = 'https://generativelanguage.googleapis.com/v1beta/$_model:generateContent';

  Future<String> ask(String question) async {
    final apiKey = await _storage.read(key: 'ai_api_key');
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API key tidak tersedia. Silakan atur di pengaturan.');
    }

    final response = await http.post(
      Uri.parse('$_apiUrl?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': question}
            ]
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final candidates = data['candidates'] as List?;
      if (candidates != null && candidates.isNotEmpty) {
        return candidates[0]['content']['parts'][0]['text'];
      }
      return 'Tidak ada respon yang dihasilkan oleh AI.';
    } else {
      try {
        final errData = jsonDecode(response.body);
        final msg = errData['error']?['message'] ?? 'Status ${response.statusCode}';
        throw Exception(msg);
      } catch (e) {
        if (e is Exception && !e.toString().startsWith('FormatException')) {
          rethrow;
        }
        throw Exception('Gagal memanggil AI API: ${response.statusCode}');
      }
    }
  }

  Future<void> saveApiKey(String key) async {
    await _storage.write(key: 'ai_api_key', value: key);
  }
}
