import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import '../../domain/quote.dart';
import '../../theme/theme.dart';
import '../atoms/direction_triangle.dart';
import '../atoms/skeleton_box.dart';
import '../atoms/text_styles.dart';

// 상세 화면의 현재가 + 등락 한 줄.  179,700  ▼ 400 (-0.22%)
// 시세가 없다면 스켈레톤을 보여준다.
class DetailPriceSummary extends StatelessWidget {
  const DetailPriceSummary({super.key, required this.quote});

  final Quote? quote;

  static const double _gap = 8;               // 현재가와 등락 사이
  static const double _priceLineHeight = 36;
  static const double _changeLineHeight = 20;

  @override
  Widget build(BuildContext context) {
    final quote = this.quote;

    return Row(
      // 글자 밑줄(baseline)을 맞춰서 큰 글자와 작은 글자가 같은 줄에 앉게 한다.
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: quote == null ? _skeleton() : _content(context, quote),
    );
  }

  List<Widget> _content(BuildContext context, Quote quote) {
    final colors = context.colors;
    final color = switch (quote.direction) {
      PriceDirection.up => colors.priceUpText,
      PriceDirection.down => colors.priceDownText,
      PriceDirection.flat => colors.priceFlatText,
    };

    return [
      Text(
        formatPrice(quote.price),
        maxLines: 1,
        style: TextStyles.detailPrice.copyWith(color: colors.textPrimary),
      ),
      const SizedBox(width: _gap),
      // 삼각형은 baseline이 없어서, 글자와 한 묶음으로 묶어 글자의 baseline을 따르게 한다.
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DirectionTriangle(direction: quote.direction, color: color),
          Text(
            formatDetailChange(quote.change, quote.changeRate),
            maxLines: 1,
            style: TextStyles.detailChange.copyWith(color: color),
          ),
        ],
      ),
    ];
  }

  // 글자 줄 높이는 유지하고, 안쪽 박스만 글자보다 조금 작게 그린다.
  List<Widget> _skeleton() => [
    _skeletonLine(lineHeight: _priceLineHeight, width: 128, height: 28),
    const SizedBox(width: _gap),
    _skeletonLine(lineHeight: _changeLineHeight, width: 96, height: 14),
  ];

  Widget _skeletonLine({
    required double lineHeight,
    required double width,
    required double height,
  }) =>
      Padding(
        padding: EdgeInsets.symmetric(vertical: (lineHeight - height) / 2),
        child: SkeletonBox(width: width, height: height),
      );
}
