import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/core/core.dart';

void main() {
  group('plainTextPreview', () {
    test('strips HTML tags from web messages', () {
      expect(plainTextPreview('<p>hey</p>'), 'hey');
      expect(
        plainTextPreview('<p>Hello <strong>team</strong></p><p>see you</p>'),
        'Hello team see you',
      );
    });

    test('decodes HTML entities', () {
      expect(
        plainTextPreview('<p>Tom &amp; Jerry &lt;3 &quot;hi&quot;</p>'),
        'Tom & Jerry <3 "hi"',
      );
    });

    test('removes inline Markdown markers from desktop messages', () {
      expect(
        plainTextPreview('**Fixed** it, *really* ~~maybe~~ `now`'),
        'Fixed it, really maybe now',
      );
    });

    test('returns empty text for markup-only content', () {
      expect(plainTextPreview('<p></p>'), '');
      expect(plainTextPreview('   '), '');
    });

    test('keeps short text unchanged', () {
      expect(plainTextPreview('Hello! 👋'), 'Hello! 👋');
    });

    test('truncates long text to 80 characters with an ellipsis', () {
      final result = plainTextPreview('a' * 100);
      expect(result, '${'a' * 77}...');
    });

    test('never cuts an emoji in half when truncating', () {
      // The emoji sits exactly at the cut point (code points 77-78).
      final text = '${'a' * 76}😀${'b' * 10}';

      final result = plainTextPreview(text);

      // The old substring(0, 77) kept only half of the emoji, shown as "�".
      expect(result, '${'a' * 76}😀...');
    });
  });
}
