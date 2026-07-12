import 'package:flutter_test/flutter_test.dart';
import 'package:plage_review/features/comments/domain/comment_validation.dart';

void main() {
  test('rejects empty text', () {
    expect(validateCommentText(''), isNotNull);
  });

  test('rejects whitespace-only text', () {
    expect(validateCommentText('   \n  '), isNotNull);
  });

  test('accepts normal text', () {
    expect(validateCommentText('Super endroit, peu de monde ce matin !'), isNull);
  });

  test('rejects text past the max length', () {
    final tooLong = 'a' * 301;
    expect(validateCommentText(tooLong), isNotNull);
  });

  test('accepts text exactly at the max length', () {
    final exact = 'a' * 300;
    expect(validateCommentText(exact), isNull);
  });
}
