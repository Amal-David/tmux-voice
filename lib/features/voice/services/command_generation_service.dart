import 'dart:convert';

import 'package:http/http.dart' as http;

class CommandGenerationService {
  CommandGenerationService(this._client);

  final http.Client _client;

  Future<String> generateCommand({
    required String transcript,
    required String prompt,
    required String apiKey,
    required String model,
    String? context,
  }) async {
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
    );

    final fullPrompt = StringBuffer();
    fullPrompt.writeln(prompt);
    if (context != null && context.isNotEmpty) {
      fullPrompt.writeln('\n--- SCREEN CONTEXT ---');
      fullPrompt.writeln(context);
      fullPrompt.writeln('--- END CONTEXT ---\n');
    }
    fullPrompt.writeln('User request: $transcript');

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {
              'text': fullPrompt.toString(),
            }
          ]
        }
      ],
    });

    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Command generation failed (${response.statusCode}): ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = data['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      throw Exception('No command suggestions returned');
    }

    final first = candidates.first as Map<String, dynamic>;
    final content = first['content'] as Map<String, dynamic>?;
    final parts = content?['parts'] as List?;
    if (parts == null || parts.isEmpty) {
      throw Exception('Invalid response payload');
    }

    final buffer = StringBuffer();
    for (final part in parts) {
      final text = (part as Map<String, dynamic>)['text'] as String?;
      if (text != null) {
        buffer.write(text);
      }
    }

    final command = buffer.toString().trim();
    if (command.isEmpty) {
      throw Exception('Received empty command');
    }
    return command;
  }
}
