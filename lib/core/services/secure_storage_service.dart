import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class SecureStorageService {
  const SecureStorageService();

  Future<String?> read(String key);

  Future<void> write(String key, String? value);
}

class FlutterSecureStorageService extends SecureStorageService {
  const FlutterSecureStorageService(this._storage);

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String? value) {
    if (value == null) {
      return _storage.delete(key: key);
    }
    return _storage.write(key: key, value: value);
  }
}
