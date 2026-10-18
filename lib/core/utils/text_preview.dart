import 'package:zedu/core/core.dart';

/// Plain-text preview of a message, for places that can't render rich text
/// (e.g. desktop notifications).
///
/// Message content arrives as HTML from the web app (`<p>hey</p>`) or as
/// inline Markdown from desktop (`**bold**`, `_italic_`, `[docs](url)`), so
/// both are stripped. Truncation counts user-perceived characters (grapheme
/// clusters), so an emoji, including skin-tone and joined emoji, is never cut
/// apart.
String plainTextPreview(String content, {int maxLength = 80}) {
  var text = content.replaceAll(_lineBreak, ' ').replaceAll(_htmlTag, '');
  text = _decodeHtmlEntities(text);
  text = text
      .replaceAllMapped(_markdownLink, (match) => match[1]!)
      .replaceAllMapped(
        RegExp(r'(\*\*|~~|`|\*)(.+?)\1'),
        (match) => match[2]!,
      )
      .replaceAllMapped(_underscoreEmphasis, (match) => match[2]!);
  text = text.replaceAll(RegExp(r'\s+'), ' ').trim();

  final characters = text.characters;
  if (characters.length <= maxLength) return text;
  return '${characters.take(maxLength - 3).string}...';
}

/// A `<br>` (with or without attributes) or the end of a block element,
/// which become a space so the words on either side stay apart.
final _lineBreak = RegExp(
  r'''<br\b[^<>"']*(?:(?:"[^"]*"|'[^']*')[^<>"']*)*>|</(p|div|li|h[1-6])\s*>''',
  caseSensitive: false,
);

/// An HTML tag: `<` followed by a tag name, so plain text such as `2 < 3 > 1`
/// is kept. Quoted attribute values may contain `>`.
final _htmlTag = RegExp(
  r'''</?[a-zA-Z][^<>"']*(?:(?:"[^"]*"|'[^']*')[^<>"']*)*>''',
);

/// `_emphasis_` / `__strong__`. The markers must not touch a word character
/// on the outside, so underscores inside words such as `snake_case` are kept.
final _underscoreEmphasis = RegExp(r'(?<!\w)(__|_)(\S(?:.*?\S)?)\1(?!\w)');

/// An inline Markdown link or image, `[label](url)` / `![alt](url)`.
final _markdownLink = RegExp(r'!?\[([^\]]*)\]\([^)\s]*\)');

String _decodeHtmlEntities(String text) => text
    .replaceAll('&nbsp;', ' ')
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&quot;', '"')
    .replaceAll('&#39;', "'")
    .replaceAll('&#x27;', "'")
    .replaceAll('&amp;', '&');
