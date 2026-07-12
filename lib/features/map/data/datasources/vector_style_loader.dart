import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart' show ThemeReader;

/// Loads the bundled Playful Minimalist basemap style and resolves its
/// vector tile source(s) against their TileJSON endpoint.
///
/// The style/theme (colours) is a local asset so it never depends on a
/// third party staying online — only the actual tile geometry does.
class VectorStyleLoader {
  const VectorStyleLoader({
    this.assetPath = 'assets/map_style/playful_light.json',
  });

  final String assetPath;

  Future<Style> load() async {
    final style =
        jsonDecode(await rootBundle.loadString(assetPath)) as Map<String, dynamic>;
    final sources = (style['sources'] as Map).cast<String, dynamic>();

    final providerByName = <String, VectorTileProvider>{};
    for (final entry in sources.entries) {
      final source = (entry.value as Map).cast<String, dynamic>();
      if (source['type'] != 'vector') continue;
      providerByName[entry.key] = await _resolveProvider(source);
    }

    return Style(
      theme: ThemeReader().read(style),
      providers: TileProviders(providerByName),
    );
  }

  Future<VectorTileProvider> _resolveProvider(
    Map<String, dynamic> source,
  ) async {
    final tileJsonUrl = source['url'] as String;
    final response = await http.get(Uri.parse(tileJsonUrl));
    if (response.statusCode != 200) {
      throw Exception(
        'TileJSON request failed for $tileJsonUrl: HTTP ${response.statusCode}',
      );
    }
    final tileJson = jsonDecode(response.body) as Map<String, dynamic>;
    final tiles = (tileJson['tiles'] as List).cast<String>();
    return NetworkVectorTileProvider(
      urlTemplate: tiles.first,
      maximumZoom: (tileJson['maxzoom'] as num?)?.toInt() ?? 14,
      minimumZoom: (tileJson['minzoom'] as num?)?.toInt() ?? 0,
    );
  }
}
