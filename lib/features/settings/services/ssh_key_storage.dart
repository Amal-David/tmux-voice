import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/utils/ssh_key_generator.dart';

/// Secure storage service for SSH keys (works on Android & iOS)
class SshKeyStorage {
  static const _storage = FlutterSecureStorage();
  static const _keysListKey = 'ssh_keys_list';
  static const _keyPrefix = 'ssh_key_';

  /// Get all stored SSH key fingerprints and labels
  static Future<List<SshKeyInfo>> listKeys() async {
    try {
      final listJson = await _storage.read(key: _keysListKey);
      if (listJson == null) return [];

      final List<dynamic> list = json.decode(listJson);
      return list.map((item) => SshKeyInfo.fromJson(item)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Store a new SSH key pair
  static Future<void> storeKey(SshKeyPair keyPair) async {
    // Store the actual key data
    final keyId = _generateKeyId(keyPair.fingerprint);
    await _storage.write(
      key: '$_keyPrefix$keyId',
      value: json.encode(keyPair.toJson()),
    );

    // Update the keys list
    final keys = await listKeys();
    keys.add(SshKeyInfo(
      id: keyId,
      label: keyPair.label,
      fingerprint: keyPair.fingerprint,
      bitLength: keyPair.bitLength,
      createdAt: keyPair.createdAt,
    ));

    await _storage.write(
      key: _keysListKey,
      value: json.encode(keys.map((k) => k.toJson()).toList()),
    );
  }

  /// Get a specific SSH key pair by ID
  static Future<SshKeyPair?> getKey(String keyId) async {
    try {
      final keyJson = await _storage.read(key: '$_keyPrefix$keyId');
      if (keyJson == null) return null;

      return SshKeyPair.fromJson(json.decode(keyJson));
    } catch (e) {
      return null;
    }
  }

  /// Delete an SSH key
  static Future<void> deleteKey(String keyId) async {
    // Delete the key data
    await _storage.delete(key: '$_keyPrefix$keyId');

    // Update the keys list
    final keys = await listKeys();
    keys.removeWhere((k) => k.id == keyId);

    await _storage.write(
      key: _keysListKey,
      value: json.encode(keys.map((k) => k.toJson()).toList()),
    );
  }

  /// Generate a unique key ID from fingerprint
  static String _generateKeyId(String fingerprint) {
    return fingerprint.replaceAll(':', '').replaceAll('SHA256:', '').substring(0, 16);
  }
}

/// SSH key metadata (without private key data)
class SshKeyInfo {
  const SshKeyInfo({
    required this.id,
    required this.label,
    required this.fingerprint,
    required this.bitLength,
    required this.createdAt,
  });

  final String id;
  final String label;
  final String fingerprint;
  final int bitLength;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'fingerprint': fingerprint,
        'bitLength': bitLength,
        'createdAt': createdAt.toIso8601String(),
      };

  factory SshKeyInfo.fromJson(Map<String, dynamic> json) => SshKeyInfo(
        id: json['id'] as String,
        label: json['label'] as String,
        fingerprint: json['fingerprint'] as String,
        bitLength: json['bitLength'] as int,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
