import 'package:flutter/material.dart';
import '../../theme/theme.dart';

// 글자 안에서 검색어와 일치하는 부분만 색을 다르게 하는 component
class HighlightText extends StatelessWidget{
  const HighlightText({
    super.key,
    required this.text,
    required this.query,
    this.style,
    this.maxLines = 1,
  });

  final String text;
  final String query;
  final TextStyle? style;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final keyword = query.trim();

    if (keyword.isEmpty) {
      return Text (
        text,
        style: style,
        maxLines: maxLines,
        // 넘치는 글자 '...' 처리
        overflow: TextOverflow.ellipsis,
      );
    }

    // RegExp.escape -> 특수문자를 일반 글자로 처리
    // caseSensitive: false -> 대소문자 구분 안 함
    final pattern = RegExp(RegExp.escape(keyword), caseSensitive: false);

    final highlightStyle = TextStyle(color: context.colors.searchHighlight);

    final spans = <TextSpan>[];
    var cursor = 0;

    for (final match in pattern.allMatches(text)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, match.start)));
      }

      spans.add(TextSpan(text: match.group(0), style: highlightStyle));
      cursor = match.end;
    }

    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }

    // Text.rich는 여러 조각을 한 줄로 이어서 그리는 Text
    return Text.rich(
      TextSpan(style: style, children: spans),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}