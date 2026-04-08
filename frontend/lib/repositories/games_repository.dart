import '../core/api_client.dart';
import '../core/games_cache_storage.dart';

class GamesRepository {
  GamesRepository({
    ApiClient? apiClient,
    GamesCacheStorage? cacheStorage,
  })  : _apiClient = apiClient ?? const ApiClient(),
        _cacheStorage = cacheStorage ?? GamesCacheStorage();

  final ApiClient _apiClient;
  final GamesCacheStorage _cacheStorage;

  Future<List<dynamic>?> loadCached() {
    return _cacheStorage.load();
  }

  Future<void> saveCached(List<dynamic> payload) {
    return _cacheStorage.save(payload);
  }

  Future<List<dynamic>> refreshRemote() async {
    final payload = await _apiClient.getList('/games');
    await _cacheStorage.save(payload);
    return payload;
  }
}
