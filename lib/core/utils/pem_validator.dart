import 'dart:convert';

/// PEM key validator and formatter
class PemValidator {
  /// Validate and clean PEM private key
  static ValidationResult validatePrivateKey(String keyContent) {
    final trimmed = keyContent.trim();
    
    if (trimmed.isEmpty) {
      return ValidationResult(
        isValid: false,
        error: 'Private key is empty',
      );
    }

    // Check for PEM headers
    if (!trimmed.contains('-----BEGIN') || !trimmed.contains('-----END')) {
      return ValidationResult(
        isValid: false,
        error: 'Invalid PEM format: Missing BEGIN/END markers',
        suggestion: 'Private key must start with "-----BEGIN" and end with "-----END"',
      );
    }

    // Common PEM types
    final validTypes = [
      'RSA PRIVATE KEY',
      'PRIVATE KEY',
      'OPENSSH PRIVATE KEY',
      'EC PRIVATE KEY',
      'DSA PRIVATE KEY',
    ];

    bool hasValidType = false;
    String? detectedType;
    
    for (final type in validTypes) {
      if (trimmed.contains('BEGIN $type')) {
        hasValidType = true;
        detectedType = type;
        break;
      }
    }

    if (!hasValidType) {
      return ValidationResult(
        isValid: false,
        error: 'Unsupported key type',
        suggestion: 'Only RSA, OPENSSH, EC, and DSA private keys are supported',
      );
    }

    // Check for encrypted key (passphrase-protected)
    if (trimmed.contains('ENCRYPTED') || trimmed.contains('Proc-Type: 4,ENCRYPTED')) {
      return ValidationResult(
        isValid: false,
        error: 'Encrypted private key detected',
        suggestion: 'This app does not support passphrase-protected keys. Remove passphrase with:\n  ssh-keygen -p -m PEM -f your_key',
      );
    }

    // Clean the key (normalize newlines)
    String cleanKey = trimmed;
    
    // Replace literal \n with actual newlines
    if (cleanKey.contains('\\n')) {
      cleanKey = cleanKey.replaceAll('\\n', '\n');
    }
    
    // Ensure proper line breaks (some copy-paste issues)
    cleanKey = cleanKey
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n');
    
    // Validate base64 content (between BEGIN and END)
    final lines = cleanKey.split('\n');
    final contentLines = lines.where((line) {
      final trimmedLine = line.trim();
      return trimmedLine.isNotEmpty && 
             !trimmedLine.startsWith('-----') &&
             !trimmedLine.startsWith('Proc-Type') &&
             !trimmedLine.startsWith('DEK-Info');
    }).toList();

    for (final line in contentLines) {
      if (!_isValidBase64(line.trim())) {
        return ValidationResult(
          isValid: false,
          error: 'Invalid key content: Contains non-base64 characters',
          suggestion: 'The key may be corrupted. Try exporting it again.',
        );
      }
    }

    return ValidationResult(
      isValid: true,
      cleanedKey: cleanKey,
      keyType: detectedType,
    );
  }

  /// Check if string is valid base64
  static bool _isValidBase64(String str) {
    if (str.isEmpty) return true;
    
    // Base64 regex: alphanumeric + / + = (padding)
    final base64Regex = RegExp(r'^[A-Za-z0-9+/=]+$');
    return base64Regex.hasMatch(str);
  }

  /// Get key type from PEM content
  static String? getKeyType(String keyContent) {
    if (keyContent.contains('BEGIN RSA PRIVATE KEY')) return 'RSA';
    if (keyContent.contains('BEGIN OPENSSH PRIVATE KEY')) return 'OpenSSH';
    if (keyContent.contains('BEGIN EC PRIVATE KEY')) return 'EC';
    if (keyContent.contains('BEGIN DSA PRIVATE KEY')) return 'DSA';
    if (keyContent.contains('BEGIN PRIVATE KEY')) return 'PKCS#8';
    return null;
  }

  /// Check if key is encrypted
  static bool isEncrypted(String keyContent) {
    return keyContent.contains('ENCRYPTED') || 
           keyContent.contains('Proc-Type: 4,ENCRYPTED');
  }
}

/// Validation result
class ValidationResult {
  const ValidationResult({
    required this.isValid,
    this.cleanedKey,
    this.keyType,
    this.error,
    this.suggestion,
  });

  final bool isValid;
  final String? cleanedKey;
  final String? keyType;
  final String? error;
  final String? suggestion;
}
