import '../../../core/constants/app_constants.dart';

/// Trims [text] and checks it's non-empty and within [kMaxCommentLength] —
/// checked client-side first so the user gets an immediate message instead
/// of waiting on a round-trip that Firestore rules would reject anyway.
String? validateCommentText(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return 'Écris quelque chose avant d\'envoyer.';
  if (trimmed.length > kMaxCommentLength) {
    return 'Trop long (max $kMaxCommentLength caractères).';
  }
  return null;
}
