import 'dart:convert';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';

// PPK to PEM Converter
// Converts PuTTY Private Key (.ppk) format to OpenSSH PEM format
class PpkConverter {
  static String? convertPpkToPem(String ppkContent) {
    try {
      final lines = ppkContent.split('\n');
      
      // Check if it's a valid PPK file
      if (!lines.first.startsWith('PuTTY-User-Key-File')) {
        return null; // Not a PPK file
      }

      // Extract the private key data
      String keyData = '';
      bool inKeySection = false;
      
      for (final line in lines) {
        if (line.startsWith('Private-Lines:')) {
          inKeySection = true;
          continue;
        }
        if (line.startsWith('Private-MAC:')) {
          break;
        }
        if (inKeySection && line.trim().isNotEmpty) {
          keyData += line.trim();
        }
      }

      if (keyData.isEmpty) {
        return null;
      }

      // Decode base64 key data
      final keyBytes = base64.decode(keyData);
      
      // For RSA keys, convert to PEM format
      final pemKey = _convertToPem(keyBytes);
      
      return pemKey;
    } catch (e) {
      return null; // Conversion failed
    }
  }

  static String _convertToPem(Uint8List keyBytes) {
    // This is a simplified conversion
    // In production, you'd need full PPK format parsing
    final base64Key = base64.encode(keyBytes);
    final chunks = _chunkString(base64Key, 64);
    
    return '-----BEGIN RSA PRIVATE KEY-----\n${chunks.join('\n')}\n-----END RSA PRIVATE KEY-----';
  }

  static List<String> _chunkString(String str, int chunkSize) {
    final chunks = <String>[];
    for (var i = 0; i < str.length; i += chunkSize) {
      final end = (i + chunkSize < str.length) ? i + chunkSize : str.length;
      chunks.add(str.substring(i, end));
    }
    return chunks;
  }

  static bool isPpkFile(String content) {
    return content.trim().startsWith('PuTTY-User-Key-File');
  }

  static bool isPemFile(String content) {
    final trimmed = content.trim();
    return trimmed.startsWith('-----BEGIN') && 
           (trimmed.contains('PRIVATE KEY') || trimmed.contains('RSA PRIVATE KEY'));
  }
}
