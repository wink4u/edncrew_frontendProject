import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import '../../domain/quote.dart';
import '../../theme/theme.dart';
import '../atoms/price_change_text.dart';
import '../atoms/skeleton_box.dart';
import '../atoms/text_styles.dart';

// 관심 행의 오른쪽에 나오는 component
// 시세가 없다면 스켈레톤 반영
class PriceSummary extends StatelessWidget {
  const PriceSummary({super.key, required this.quote});

  final Quote? quote;

  static const double _lineGap = 2;
  static const double _priceLineHeight = 20;
  static const double _changeLineHeight = 14;

  @override
  Widget build(BuildContext context) {
    final quote = this.quote;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: quote == null ? _skeleton() : _content(context, quote)
    );
  }

  // 시세가 있다면
  List<Widget> _content(BuildContext context, Quote quote) => [
    Text(
      formatPrice(quote.price),
      maxLines: 1,
      style: TextStyles.price.copyWith(color: context.colors.textPrimary),
    ),
    const SizedBox(height: _lineGap),
    PriceChangeText.fromQuote(quote),
  ];

  // 시세가 없다면
  List<Widget> _skeleton() => [
    _skeletonLine(lineHeight: _priceLineHeight, width: 64, height: 16),
    const SizedBox(height: _lineGap),
    _skeletonLine(lineHeight: _changeLineHeight, width: 48, height: 12),
  ];

  Widget _skeletonLine({
    required double lineHeight,
    required double width,
    required double height,
  }) =>
      Padding(
        padding: EdgeInsets.symmetric(vertical: (lineHeight - height) / 2),
        child: SkeletonBox(width: width, height: height)
      );
}