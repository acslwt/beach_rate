/// Short French "time ago" label (e.g. "il y a 12 min") for timestamps shown
/// across the app's collaborative features (affluence updates, comments).
String relativeTime(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return 'à l\'instant';
  if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'il y a ${diff.inHours} h';
  return 'il y a ${diff.inDays} j';
}
