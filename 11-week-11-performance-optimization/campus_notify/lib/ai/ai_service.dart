import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';

class AiService {
  final FlutterSecureStorage _storage;
  final http.Client _client;

  AiService({http.Client? client, FlutterSecureStorage? storage})
      : _client = client ?? http.Client(),
        _storage = storage ?? const FlutterSecureStorage();

  // Model resmi terbaru sesuai instruksi Google AI Studio
  static const String _model = 'models/gemini-3.8-flash';
  final _apiUrl =
      'https://generativelanguage.googleapis.com/v1beta/$_model:generateContent';

  Future<String> ask(String question) async {
    final apiKey = await _storage.read(key: 'ai_api_key');
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API key tidak tersedia. Silakan atur di pengaturan.');
    }

    final response = await _client.post(
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

    return _parseResponse(response);
  }

  /// Ekstraksi teks dari gambar (OCR) untuk KTM, struk, dokumen, dan papan pengumuman
  Future<String> recognizeText(dynamic imageFile) async {
    final bytes = await _readFileBytes(imageFile);
    final mimeType = _detectMimeType(imageFile, isImage: true);

    const prompt =
        'Tolong lakukan Optical Character Recognition (OCR) secara akurat pada gambar ini. '
        'Ekstrak seluruh teks yang terbaca (seperti pada KTM, kuitansi/receipt, dokumen akademik, atau papan pengumuman) '
        'dan pertahankan struktur teks aslinya tanpa opini tambahan. '
        'Jika tidak ada teks sama sekali, kembalikan "Tidak ada teks yang dapat dikenali pada gambar."';

    return await _callMultimodal(
      prompt: prompt,
      bytes: bytes,
      mimeType: mimeType,
    );
  }

  /// Analisis dan pemahaman konteks gambar (Image Understanding)
  Future<String> understandImage(dynamic imageFile, {String? prompt}) async {
    final bytes = await _readFileBytes(imageFile);
    final mimeType = _detectMimeType(imageFile, isImage: true);

    final finalPrompt = (prompt != null && prompt.trim().isNotEmpty)
        ? prompt
        : 'Jelaskan dan deskripsikan secara mendalam konten yang ada di dalam gambar ini. '
            'Identifikasi objek utama, teks yang tampak, serta konteks visualnya untuk aksesibilitas pengguna.';

    return await _callMultimodal(
      prompt: finalPrompt,
      bytes: bytes,
      mimeType: mimeType,
    );
  }

  /// Transkripsi suara ke teks (Speech-to-Text) untuk input cepat dan aksesibilitas
  Future<String> speechToText(dynamic audioFile) async {
    final bytes = await _readFileBytes(audioFile);
    final mimeType = _detectMimeType(audioFile, isImage: false);

    const prompt =
        'Transkripsikan rekaman suara berikut ini ke dalam teks bahasa Indonesia secara presisi dan natural. '
        'Hanya kembalikan teks hasil transkripsi tanpa tanda kutip pembungkus atau teks pembuka. '
        'Jika rekaman suara kosong atau tidak terdengar ucapan, kembalikan "Tidak ada suara yang terdeteksi."';

    return await _callMultimodal(
      prompt: prompt,
      bytes: bytes,
      mimeType: mimeType,
    );
  }

  Future<String> _callMultimodal({
    required String prompt,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    final apiKey = await _storage.read(key: 'ai_api_key');
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API key tidak tersedia. Silakan atur di pengaturan.');
    }

    if (bytes.isEmpty) {
      throw Exception('Berkas kosong tidak dapat diproses oleh AI.');
    }

    final base64Data = base64Encode(bytes);

    final response = await _client.post(
      Uri.parse('$_apiUrl?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt},
              {
                'inline_data': {
                  'mime_type': mimeType,
                  'data': base64Data,
                }
              }
            ]
          }
        ]
      }),
    );

    return _parseResponse(response);
  }

  String _parseResponse(http.Response response) {
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final candidates = data['candidates'] as List?;
      if (candidates != null && candidates.isNotEmpty) {
        return candidates[0]['content']['parts'][0]['text'] ?? '';
      }
      return 'Tidak ada respon yang dihasilkan oleh AI.';
    } else {
      try {
        final errData = jsonDecode(response.body);
        final msg =
            errData['error']?['message'] ?? 'Status ${response.statusCode}';
        throw Exception(msg);
      } catch (e) {
        if (e is Exception && !e.toString().startsWith('FormatException')) {
          rethrow;
        }
        throw Exception('Gagal memanggil AI API: ${response.statusCode}');
      }
    }
  }

  Future<Uint8List> _readFileBytes(dynamic file) async {
    if (file is Uint8List) return file;
    if (file is List<int>) return Uint8List.fromList(file);
    if (file is XFile) return await file.readAsBytes();
    if (file is File) return await file.readAsBytes();
    try {
      return await file.readAsBytes();
    } catch (_) {
      throw ArgumentError('Tipe berkas tidak didukung: ${file.runtimeType}');
    }
  }

  String _detectMimeType(dynamic file, {required bool isImage}) {
    String path = '';
    if (file is XFile) {
      path = file.path;
    } else if (file is File) {
      path = file.path;
    } else if (file != null) {
      try {
        path = (file as dynamic).path ?? '';
      } catch (_) {}
    }

    final ext = path.contains('.') ? path.split('.').last.toLowerCase() : '';
    if (isImage) {
      if (ext == 'png') return 'image/png';
      if (ext == 'webp') return 'image/webp';
      if (ext == 'heic') return 'image/heic';
      return 'image/jpeg';
    } else {
      if (ext == 'wav') return 'audio/wav';
      if (ext == 'mp3') return 'audio/mp3';
      if (ext == 'ogg') return 'audio/ogg';
      if (ext == 'aac') return 'audio/aac';
      return 'audio/m4a';
    }
  }

  Future<void> saveApiKey(String key) async {
    await _storage.write(key: 'ai_api_key', value: key);
  }

  Future<String?> getApiKey() async {
    return await _storage.read(key: 'ai_api_key');
  }
}
