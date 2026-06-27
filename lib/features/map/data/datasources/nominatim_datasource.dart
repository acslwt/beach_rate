import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/constants/app_constants.dart';
import '../models/place_model.dart';

class NominatimDatasource {
  const NominatimDatasource(this._client);

  final http.Client _client;

  Future<List<PlaceModel>> search(String query) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q':               query,
      'format':          'json',
      'limit':           '5',
      'accept-language': 'fr',
    });

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
}
