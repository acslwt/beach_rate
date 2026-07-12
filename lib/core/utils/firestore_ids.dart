/// `MapSpot.id`/`NearbySpot.id` look like `"node/123456"` — the `/` is part
/// of the OSM id and is meaningful for the app, but Firestore's `.doc(path)`
/// treats `/` as a path separator, which turns a single document id into a
/// multi-segment path and trips the SDK's `isDocument()` assertion. Every
/// Firestore document built from a spot/zone id (affluence, comments, ...)
/// goes through this first.
String firestoreZoneDocId(String zoneId) => zoneId.replaceAll('/', '_');
