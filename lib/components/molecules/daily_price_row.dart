import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import '../../domain/candle.dart';
import '../../theme/theme.dart';
import '../atoms/skeleton_box.dart';
import '../atoms/text_styles.dart';
import 'daily_price_line.dart';

// 표의 데이터 한 행. candle이 null이면 스켈레톤.
class DailyPriceRow extends StatelessWidget {
  const DailyPriceRow({super.key, required this.candle});

  final Candle? candle;

  static const double _textHeight = 14;
  static const double _skeletonHeight = 10;

  @override
  Widget build(BuildContext context) {
    final candle = this.candle;
    if (candle == null) {
      return DailyPriceLine(
        date: _skeleton(28),
        close: _skeleton(48),
        change: _skeleton(40),
        volume: _skeleton(56),
      );
    }

    final colors = context.colors;
    final change = candle.change;

    // 등락 색: 플러스는 상승색, 마이너스는 하락색, 0이나 모름은 보조 글자색
    final changeColor = switch (change) {
      null => colors.textSecondary,
      > 0 => colors.priceUpText,
      < 0 => colors.priceDownText,
      _ => colors.textSecondary,
    };

    Widget cell(String text, Color color) =>
        Text(text, maxLines: 1, style: TextStyles.tableCell.copyWith(color: color));

    return DailyPriceLine(
      date: cell(formatMonthDay(candle.date), colors.textSecondary),
      close: cell(formatPrice(candle.close), colors.textPrimary),
      change: cell(change == null ? '-' : formatChange(change), changeColor),
      volume: cell(formatPrice(candle.volume), colors.textSecondary),
    );
  }

  // 글자 줄 높이(14)는 유지하고 박스만 작게 그려서, 값이 오면 위치가 안 움직인다.
  Widget _skeleton(double width) => Padding(
    padding: const EdgeInsets.symmetric(vertical: (_textHeight - _skeletonHeight) / 2),
    child: SkeletonBox(width: width, height: _skeletonHeight),
  );
}
