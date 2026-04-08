import '../core/api_client.dart';
import '../core/dashboard_cache_storage.dart';

class DashboardRepository {
  DashboardRepository({
    ApiClient? apiClient,
    DashboardCacheStorage? cacheStorage,
  })  : _apiClient = apiClient ?? const ApiClient(),
        _cacheStorage = cacheStorage ?? DashboardCacheStorage();

  final ApiClient _apiClient;
  final DashboardCacheStorage _cacheStorage;

  Future<Map<String, dynamic>?> loadCached() {
    return _cacheStorage.load();
  }

  Future<Map<String, dynamic>> refreshRemote() async {
    final payload = await _apiClient.get('/dashboard');
    await _cacheStorage.save(payload);
    return payload;
  }
}
