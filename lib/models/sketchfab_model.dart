class SketchfabModel {
  final String uid;
  final String name;
  final String embedUrl;
  final String viewerUrl;
  final String thumbnailUrl;
  final String authorName;
  final String authorUrl;
  final String license;
  final List<String> tags;
  final int likeCount;
  final int viewCount;
  final int glbSizeBytes;

  const SketchfabModel({
    required this.uid,
    required this.name,
    required this.embedUrl,
    required this.viewerUrl,
    required this.thumbnailUrl,
    required this.authorName,
    required this.authorUrl,
    required this.license,
    required this.tags,
    required this.likeCount,
    required this.viewCount,
    required this.glbSizeBytes,
  });

  factory SketchfabModel.fromJson(Map<String, dynamic> json) {
    final uid = json['uid'] as String? ?? '';
    final user = json['user'] as Map<String, dynamic>? ?? const {};
    final thumbnails = json['thumbnails'] as Map<String, dynamic>? ?? const {};
    final images = thumbnails['images'] as List<dynamic>? ?? const [];
    final licenseData = json['license'] as Map<String, dynamic>? ?? const {};
    final archives = json['archives'] as Map<String, dynamic>? ?? const {};
    final glbArchive = archives['glb'] as Map<String, dynamic>? ?? const {};
    final tags = (json['tags'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map((tag) => tag['name'] as String?)
        .whereType<String>()
        .toList();

    var thumbnailUrl = '';
    for (final image in images.whereType<Map<String, dynamic>>()) {
      final url = image['url'] as String?;
      if (url != null && url.isNotEmpty) {
        thumbnailUrl = url;
        break;
      }
    }

    return SketchfabModel(
      uid: uid,
      name: json['name'] as String? ?? '3D product model',
      embedUrl:
          json['embedUrl'] as String? ??
          'https://sketchfab.com/models/$uid/embed',
      viewerUrl:
          json['viewerUrl'] as String? ??
          'https://sketchfab.com/3d-models/$uid',
      thumbnailUrl: thumbnailUrl,
      authorName:
          user['displayName'] as String? ??
          user['username'] as String? ??
          'Sketchfab creator',
      authorUrl: user['profileUrl'] as String? ?? 'https://sketchfab.com',
      license: licenseData['label'] as String? ?? 'CC Attribution',
      tags: tags,
      likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
      viewCount: (json['viewCount'] as num?)?.toInt() ?? 0,
      glbSizeBytes: (glbArchive['size'] as num?)?.toInt() ?? 0,
    );
  }
}
