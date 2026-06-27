import 'package:latlong2/latlong.dart';

const LatLng kDefaultCenter = LatLng(48.8566, 2.3522);
const String kNominatimUserAgent = 'PlageApp/1.0 (com.example.plage_review)';
const String kOsmTileTemplate = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
const String kOsmPackageName = 'com.example.plage_review';

const List<String> kOverpassMirrors = [
  'https://maps.mail.ru/osm/tools/overpass/api/interpreter',
  'https://overpass-api.de/api/interpreter',
  'https://overpass.kumi.systems/api/interpreter',
];
