/// Plain-text preview of a message, for places that can't render rich text
/// (e.g. desktop notifications).
///
/// Message content arrives as HTML from the web app (`<p>hey</p>`) or as
/// inline Markdown from desktop (`**bold**`), so both are stripped. Truncation
/// counts Unicode code points rather than UTF-16 units, so an emoji is never
/// cut in half.
String plainTextPreview(String content, {int maxLength = 80}) {
  var text = content
      .replaceAll(
        RegExp(r'<br\s*/?>|</(p|div|li|h[1-6])>', caseSensitive: false),
        ' ',
      )
      .replaceAll(RegExp('<[^>]*>'), '');
  text = _decodeHtmlEntities(text);
  text = text.replaceAllMapped(
    RegExp(r'(\*\*|~~|`|\*)(.+?)\1'),
    (match) => match[2]!,
  );
  text = text.replaceAll(RegExp(r'\s+'), ' ').trim();

  final codePoints = text.runes.toList();
  if (codePoints.length <= maxLength) return text;
  return '${String.fromCharCodes(codePoints.take(maxLength - 3))}...';
}

String _decodeHtmlEntities(String text) => text
    .replaceAll('&nbsp;', ' ')
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&quot;', '"')
    .replaceAll('&#39;', "'")
    .replaceAll('&#x27;', "'")
    .replaceAll('&amp;', '&');
