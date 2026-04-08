import '../core/api_client.dart';
import '../core/knowledge_cache_storage.dart';

class KnowledgeRepository {
  KnowledgeRepository({
    ApiClient? apiClient,
    KnowledgeCacheStorage? cacheStorage,
  })  : _apiClient = apiClient ?? const ApiClient(),
        _cacheStorage = cacheStorage ?? KnowledgeCacheStorage();

  final ApiClient _apiClient;
  final KnowledgeCacheStorage _cacheStorage;

  Future<Map<String, dynamic>?> loadCached() {
    return _cacheStorage.load();
  }

  Future<Map<String, dynamic>> refreshRemote({String? query}) async {
    final normalizedQuery = query?.trim() ?? '';
    final games = await _apiClient.getList('/games');
    final faqs = await _apiClient.getList('/faqs', query: normalizedQuery.isEmpty ? null : {'q': normalizedQuery});
    final payload = <String, dynamic>{
      'query': normalizedQuery,
      'games': games,
      'faqs': faqs,
    };
    if (normalizedQuery.isEmpty) {
      await _cacheStorage.save(payload);
    }
    return payload;
  }
}
