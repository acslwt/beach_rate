import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/place_model.dart';

class NominatimDatasource {
  const NominatimDatasource(this._client);

  final http.Client _client;

  /// [near], when given, adds a soft viewbox bias so results skew toward
  /// that location instead of Nominatim's global "importance" ranking —
  /// this only affects *which* results come back; ordering them by exact
  /// distance is done separately (see `sortPlacesByProximity`).
  Future<List<PlaceModel>> search(String query, {LatLng? near}) async {
    final params = {
      'q':               query,
      'format':          'json',
      'limit':           '$kSearchFetchLimit',
      'accept-language': 'fr',
    };
    if (near != null) {
      params['viewbox'] = _viewboxAround(near, kSearchProximityBiasDegrees);
    }

    final uri = Uri.https('nominatim.openstreetmap.org', '/search', params);

    final response = await _client.get(uri, headers: {
      'User-Agent': kNominatimUserAgent,
    });

    if (response.statusCode != 200) return [];

    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .cast<Map<String, dynamic>>()
        .map(PlaceModel.fromJson)
        .toList();
  }

  /// Nominatim's `viewbox=<left>,<top>,<right>,<bottom>`, i.e.
  /// `west,north,east,south` — deliberately *not* paired with `bounded=1`
  /// so a real match just outside the box still comes back.
  String _viewboxAround(LatLng center, double delta) {
    final west = center.longitude - delta;
    final east = center.longitude + delta;
    final north = center.latitude + delta;
    final south = center.latitude - delta;
    return '$west,$north,$east,$south';
  }
}
