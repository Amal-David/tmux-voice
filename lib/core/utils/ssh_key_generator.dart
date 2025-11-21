import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';
import 'package:asn1lib/asn1lib.dart';

/// Cross-platform SSH key generation using pure Dart (works on Android & iOS)
class SshKeyGenerator {
  /// Generate RSA key pair (2048 or 4096 bit)
  static Future<SshKeyPair> generateRsaKeyPair({
    int bitLength = 2048,
    String label = 'mobile-key',
  }) async {
    // Validate bit length
    if (bitLength != 2048 && bitLength != 4096) {
      throw ArgumentError('Bit length must be 2048 or 4096');
    }

    // Generate RSA key pair using PointyCastle (pure Dart, cross-platform)
    final secureRandom = _getSecureRandom();
    final keyGen = RSAKeyGenerator()
      ..init(ParametersWithRandom(
        RSAKeyGeneratorParameters(BigInt.from(65537), bitLength, 64),
        secureRandom,
      ));

    final keyPair = keyGen.generateKeyPair();
    final publicKey = keyPair.publicKey as RSAPublicKey;
    final privateKey = keyPair.privateKey as RSAPrivateKey;

    // Convert to OpenSSH formats
    final publicKeyString = _rsaPublicKeyToOpenSSH(publicKey, label);
    final privateKeyString = _rsaPrivateKeyToPEM(privateKey);
    final fingerprint = _generateFingerprint(publicKey);

    return SshKeyPair(
      publicKey: publicKeyString,
      privateKey: privateKeyString,
      fingerprint: fingerprint,
      label: label,
      bitLength: bitLength,
      createdAt: DateTime.now(),
    );
  }

  /// Generate secure random for key generation
  static SecureRandom _getSecureRandom() {
    final secureRandom = FortunaRandom();
    final random = Random.secure();
    final seeds = List<int>.generate(32, (_) => random.nextInt(256));
    secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));
    return secureRandom;
  }

  /// Convert RSA public key to OpenSSH format (ssh-rsa ...)
  static String _rsaPublicKeyToOpenSSH(RSAPublicKey publicKey, String label) {
    // Build OpenSSH public key format
    final writer = _SSHWriter();
    writer.writeString('ssh-rsa');
    writer.writeBigInt(publicKey.exponent!);
    writer.writeBigInt(publicKey.modulus!);

    final bytes = writer.toBytes();
    final base64Key = base64.encode(bytes);

    return 'ssh-rsa $base64Key $label';
  }

  /// Convert RSA private key to PEM format (OpenSSH compatible)
  static String _rsaPrivateKeyToPEM(RSAPrivateKey privateKey) {
    // Encode private key to ASN.1 DER format
    final sequence = ASN1Sequence();
    sequence.add(ASN1Integer(BigInt.zero)); // version
    sequence.add(ASN1Integer(privateKey.modulus!));
    sequence.add(ASN1Integer(privateKey.exponent!));
    sequence.add(ASN1Integer(privateKey.privateExponent!));
    sequence.add(ASN1Integer(privateKey.p!));
    sequence.add(ASN1Integer(privateKey.q!));
    
    // Calculate d mod (p-1) and d mod (q-1)
    final dP = privateKey.privateExponent! % (privateKey.p! - BigInt.one);
    final dQ = privateKey.privateExponent! % (privateKey.q! - BigInt.one);
    sequence.add(ASN1Integer(dP));
    sequence.add(ASN1Integer(dQ));
    
    // Calculate coefficient (q^-1 mod p)
    final qInv = privateKey.q!.modInverse(privateKey.p!);
    sequence.add(ASN1Integer(qInv));

    final bytes = sequence.encodedBytes;
    final base64Key = base64.encode(bytes);

    // Split into 64-character lines
    final lines = <String>[];
    for (var i = 0; i < base64Key.length; i += 64) {
      final end = i + 64 < base64Key.length ? i + 64 : base64Key.length;
      lines.add(base64Key.substring(i, end));
    }

    return '-----BEGIN RSA PRIVATE KEY-----\n${lines.join('\n')}\n-----END RSA PRIVATE KEY-----';
  }

  /// Generate SSH key fingerprint (SHA256)
  static String _generateFingerprint(RSAPublicKey publicKey) {
    final writer = _SSHWriter();
    writer.writeString('ssh-rsa');
    writer.writeBigInt(publicKey.exponent!);
    writer.writeBigInt(publicKey.modulus!);

    final bytes = writer.toBytes();
    final digest = SHA256Digest();
    final hash = digest.process(bytes);
    final base64Hash = base64.encode(hash).replaceAll('=', '');

    return 'SHA256:$base64Hash';
  }
}

/// SSH key pair data class
class SshKeyPair {
  const SshKeyPair({
    required this.publicKey,
    required this.privateKey,
    required this.fingerprint,
    required this.label,
    required this.bitLength,
    required this.createdAt,
  });

  final String publicKey;
  final String privateKey;
  final String fingerprint;
  final String label;
  final int bitLength;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'publicKey': publicKey,
        'privateKey': privateKey,
        'fingerprint': fingerprint,
        'label': label,
        'bitLength': bitLength,
        'createdAt': createdAt.toIso8601String(),
      };

  factory SshKeyPair.fromJson(Map<String, dynamic> json) => SshKeyPair(
        publicKey: json['publicKey'] as String,
        privateKey: json['privateKey'] as String,
        fingerprint: json['fingerprint'] as String,
        label: json['label'] as String,
        bitLength: json['bitLength'] as int,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

/// Helper class to write SSH wire format
class _SSHWriter {
  final _buffer = <int>[];

  void writeString(String value) {
    final bytes = utf8.encode(value);
    writeBytes(bytes);
  }

  void writeBytes(List<int> bytes) {
    writeUint32(bytes.length);
    _buffer.addAll(bytes);
  }

  void writeBigInt(BigInt value) {
    var bytes = _bigIntToBytes(value);
    // Add leading zero if high bit is set (to indicate positive number)
    if (bytes.isNotEmpty && bytes[0] & 0x80 != 0) {
      bytes = [0, ...bytes];
    }
    writeBytes(bytes);
  }

  void writeUint32(int value) {
    _buffer.addAll([
      (value >> 24) & 0xff,
      (value >> 16) & 0xff,
      (value >> 8) & 0xff,
      value & 0xff,
    ]);
  }

  Uint8List toBytes() => Uint8List.fromList(_buffer);

  List<int> _bigIntToBytes(BigInt bigInt) {
    var bytes = <int>[];
    while (bigInt > BigInt.zero) {
      bytes.insert(0, (bigInt & BigInt.from(0xff)).toInt());
      bigInt = bigInt >> 8;
    }
    return bytes.isEmpty ? [0] : bytes;
  }
}
