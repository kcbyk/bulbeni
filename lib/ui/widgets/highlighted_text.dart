import 'package:flutter/material.dart';
import '../../core/utils/turkish_search_helper.dart';

class HighlightedText extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle? baseStyle;
  final TextStyle? highlightStyle;
  final Color? highlightBackgroundColor;
  final int maxLines;
  final TextOverflow overflow;

  const HighlightedText({
    super.key,
    required this.text,
    required this.query,
    this.baseStyle,
    this.highlightStyle,
    this.highlightBackgroundColor,
    this.maxLines = 2,
    this.overflow = TextOverflow.ellipsis,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBase = baseStyle ??
        TextStyle(
          fontSize: 13,
          color: isDark ? const Color(0xFF9E9EA4) : const Color(0xFF6B7280),
          height: 1.3,
        );

    final defaultHighlight = highlightStyle ??
        TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : Colors.black,
        );

    final highlightBg = highlightBackgroundColor ??
        (isDark ? const Color(0xFF2C2C30) : const Color(0xFFE5E7EB));

    if (query.trim().isEmpty || text.isEmpty) {
      return Text(
        text,
        style: defaultBase,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    final normText = TurkishSearchHelper.normalize(text);
    final normQuery = TurkishSearchHelper.normalize(query.trim());

    final List<InlineSpan> spans = [];
    int start = 0;

    while (start < text.length) {
      final index = normText.indexOf(normQuery, start);
      if (index == -1) {
        spans.add(TextSpan(text: text.substring(start), style: defaultBase));
        break;
      }

      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index), style: defaultBase));
      }

      final matchEnd = index + normQuery.length;
      final matchedOriginal = text.substring(index, matchEnd.clamp(0, text.length));

      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            decoration: BoxDecoration(
              color: highlightBg,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              matchedOriginal,
              style: defaultHighlight,
            ),
          ),
        ),
      );

      start = matchEnd;
    }

    return RichText(
      text: TextSpan(children: spans),
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
