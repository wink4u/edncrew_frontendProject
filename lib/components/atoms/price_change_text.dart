import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import '../../domain/quote.dart';
import '../../theme/theme.dart';
import 'text_styles.dart';

class PriceChangeText extends StatelessWidget {
  const PriceChangeText({
    super.key,
    required this.change,
    required this.changeRate,
    required this.direction,
    this.style,
  });

  PriceChangeText.fromQuote(Quote quote, {Key? key, TextStyle? style})
    : this (
      key: key,
      change: quote.change,
      changeRate: quote.changeRate,
      direction: quote.direction,
      style: style,
    );

  final int change;
  final double changeRate;
  final PriceDirection direction;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    // 방향에 따른 색. 상승, 하락, 동률
    final color = switch (direction) {
      PriceDirection.up => colors.priceUpText,
      PriceDirection.down => colors.priceDownText,
      PriceDirection.flat => colors.priceFlatText,
    };

    return Text(
      formatChangeWithRate(change, changeRate),
      maxLines: 1,
      style: (style ?? TextStyles.priceChange).copyWith(color: color),
    );
  }
}