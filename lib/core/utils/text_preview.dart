import 'package:zedu/core/core.dart';

/// Plain-text preview of a message, for places that can't render rich text
/// (e.g. desktop notifications).
///
/// Message content arrives as HTML from the web app (`<p>hey</p>`) or as
/// inline Markdown from desktop (`**bold**`, `[docs](url)`), so both are
/// stripped. Truncation counts user-perceived characters (grapheme clusters),
/// so an emoji, including skin-tone and joined emoji, is never cut apart.
String plainTextPreview(String content, {int maxLength = 80}) {
  var text = content
      .replaceAll(
        RegExp(r'<br\s*/?>|</(p|div|li|h[1-6])>', caseSensitive: false),
        ' ',
      )
      .replaceAll(_htmlTag, '');
  text = _decodeHtmlEntities(text);
  text = text
      .replaceAllMapped(_markdownLink, (match) => match[1]!)
      .replaceAllMapped(
        RegExp(r'(\*\*|~~|`|\*)(.+?)\1'),
        (match) => match[2]!,
      );
  text = text.replaceAll(RegExp(r'\s+'), ' ').trim();

  final characters = text.characters;
  if (characters.length <= maxLength) return text;
  return '${characters.take(maxLength - 3).string}...';
}

/// An HTML tag: `<` followed by a tag name, so plain text such as `2 < 3 > 1`
/// is kept. Quoted attribute values may contain `>`.
final _htmlTag = RegExp(r'''</?[a-zA-Z][^<>"']*(?:(?:"[^"]*"|'[^']*')[^<>"']*)*>''');

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
