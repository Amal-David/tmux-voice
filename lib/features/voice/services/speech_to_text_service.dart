import 'dart:io';

import 'package:http/http.dart' as http;

class SpeechToTextService {
  SpeechToTextService(this._client);

  final http.Client _client;

  Future<String> transcribe({
    required File audioFile,
    required String apiKey,
    required String model,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://api.groq.com/openai/v1/audio/transcriptions'),
    )
      ..headers['Authorization'] = 'Bearer $apiKey'
      ..fields['model'] = model
      ..fields['response_format'] = 'text'
      ..files.add(await http.MultipartFile.fromPath('file', audioFile.path));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.body.trim();
    }
    throw Exception('STT failed (${response.statusCode}): ${response.body}');
  }
}
