import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/product.dart';
import '../models/sketchfab_model.dart';

class SketchfabCatalogService {
  static const _aiGeneratedTags = {
    'ai-generated',
    'aigenerated',
    'createdwithai',
    'generative-ai',
    'image-to-3d-model-ai',
    'meshy',
    'tripo',
  };

  final http.Client _client;
  final bool _ownsClient;

  SketchfabCatalogService({http.Client? client})
    : _client = client ?? http.Client(),
      _ownsClient = client == null;

  Future<List<SketchfabModel>> searchModels(Product product) async {
    final query =
        product.model3dSearchTerm ??
        '${product.brand ?? ''} ${product.title} ${product.category}';
    final uri = Uri.https('api.sketchfab.com', '/v3/search', {
      'type': 'models',
      'q': query.trim(),
      'downloadable': 'true',
      'license': 'by',
      'count': '24',
      'sort_by': '-relevance',
    });
    final response = await _client
        .get(uri, headers: const {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw http.ClientException(
        'Sketchfab returned ${response.statusCode}',
        uri,
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final results = decoded['results'] as List<dynamic>? ?? const [];
    final requiredTerms = product.model3dKeywords
        .map((term) => term.toLowerCase())
        .toList();

    final models = results
        .whereType<Map<String, dynamic>>()
        .map(SketchfabModel.fromJson)
        .where((model) => model.uid.isNotEmpty)
        .where(
          (model) =>
              model.glbSizeBytes == 0 || model.glbSizeBytes <= 50 * 1024 * 1024,
        )
        .where((model) => !_isAiGenerated(model))
        .where((model) => _matchesProduct(model, requiredTerms))
        .toList();
    models.sort((first, second) {
      final likes = second.likeCount.compareTo(first.likeCount);
      return likes != 0 ? likes : second.viewCount.compareTo(first.viewCount);
    });
    return models;
  }

  bool _isAiGenerated(SketchfabModel model) =>
      model.tags.any((tag) => _aiGeneratedTags.contains(tag.toLowerCase()));

  bool _matchesProduct(SketchfabModel model, List<String> requiredTerms) {
    if (requiredTerms.isEmpty) return true;
    final modelWords = _searchTokens(model.name);
    return requiredTerms.any((term) {
      final requiredWords = _searchTokens(term);
      return requiredWords.isNotEmpty &&
          requiredWords.every(modelWords.contains);
    });
  }

  List<String> _searchTokens(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .map((word) {
          if (word == 'watches') return 'watch';
          if (word.length > 3 && word.endsWith('s')) {
            return word.substring(0, word.length - 1);
          }
          return word;
        })
        .toList();
  }

  void close() {
    if (_ownsClient) _client.close();
  }
}
