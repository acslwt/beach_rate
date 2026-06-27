import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/constants/app_constants.dart';
import '../models/map_spot_model.dart';

class OverpassDatasource {
  const OverpassDatasource(this._client);

  final http.Client _client;

  Future<List<MapSpotModel>> fetchSpots({
    required String south,
    required String west,
    required String north,
    required String east,
  }) async {
    final query =
        '[out:json][timeout:15];'
        '('
        'node["natural"="beach"]($south,$west,$north,$east);'
        'way["natural"="beach"]($south,$west,$north,$east);'
        'node["natural"="water"]["water"="lake"]($south,$west,$north,$east);'
        'way["natural"="water"]["water"!="pool"]($south,$west,$north,$east);'
        'way["waterway"="river"]($south,$west,$north,$east);'
        ');'
        'out center 60;';

    for (final url in kOverpassMirrors) {
      try {
        final response = await _client
            .post(Uri.parse(url), body: {'data': query})
            .timeout(const Duration(seconds: 20));

        if (response.statusCode != 200) continue;
        final body = response.body;
        if (!body.trimLeft().startsWith('{')) continue;

        final data    = jsonDecode(body) as Map<String, dynamic>;
        final elements = (data['elements'] as List<dynamic>?) ?? [];
        final seen    = <String>{};
        final spots   = <MapSpotModel>[];

        for (final el in elements.cast<Map<String, dynamic>>()) {
          final spot = MapSpotModel.fromOverpassElement(el);
          if (spot == null) continue;

          // Deduplicate by ~100 m grid.
          final key =
              '${spot.location.latitude.toStringAsFixed(3)},'
              '${spot.location.longitude.toStringAsFixed(3)}';
          if (!seen.add(key)) continue;
          spots.add(spot);
        }
        return spots;
      } catch (_) {
        continue;
      }
    }
    return [];
  }
}
