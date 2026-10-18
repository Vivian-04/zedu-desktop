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

    test('handles > inside quoted attribute values', () {
      expect(plainTextPreview('<a title="2 > 1">Open</a>'), 'Open');
    });

    test('keeps plain-text angle brackets that are not tags', () {
      expect(plainTextPreview('2 < 3 > 1'), '2 < 3 > 1');
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

    test('shows the label of Markdown links and images', () {
      expect(
        plainTextPreview(
          'see [docs](https://example.com) and ![logo](https://x.png)',
        ),
        'see docs and logo',
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
      // The emoji sits exactly at the cut point (character 77).
      final text = '${'a' * 76}😀${'b' * 10}';

      final result = plainTextPreview(text);

      // The old substring(0, 77) kept only half of the emoji, shown as "�".
      expect(result, '${'a' * 76}😀...');
    });

    test('keeps skin-tone and joined emoji whole at the cut point', () {
      expect(
        plainTextPreview('${'a' * 76}👍🏽 more text here'),
        '${'a' * 76}👍🏽...',
      );
      expect(
        plainTextPreview('${'a' * 76}👨‍👩‍👧 more text here'),
        '${'a' * 76}👨‍👩‍👧...',
      );
    });
  });
}
