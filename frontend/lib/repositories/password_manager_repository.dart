import '../core/api_client.dart';
import '../core/password_manager_cache_storage.dart';

class PasswordManagerRepository {
  PasswordManagerRepository({
    ApiClient? apiClient,
    PasswordManagerCacheStorage? cacheStorage,
  })  : _apiClient = apiClient ?? const ApiClient(),
        _cacheStorage = cacheStorage ?? PasswordManagerCacheStorage();

  final ApiClient _apiClient;
  final PasswordManagerCacheStorage _cacheStorage;

  Future<Map<String, dynamic>?> loadCached() {
    return _cacheStorage.load();
  }

  Future<Map<String, dynamic>> refreshRemote() async {
    final games = await _apiClient.getList('/games');
    final credentials = await _apiClient.getList('/credentials');
    final payload = <String, dynamic>{
      'games': games,
      'credentials': credentials,
    };
    await _cacheStorage.save(payload);
    return payload;
  }
}
