import 'package:flutter/material.dart';

import '../../theme/theme.dart';
import '../atoms/text_styles.dart';
import 'daily_price_line.dart';

// 표 머리글: 날짜 / 종가 / 등락 / 거래량
class DailyPriceHeader extends StatelessWidget {
  const DailyPriceHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final style = TextStyles.tableHeader.copyWith(color: context.colors.textSecondary);
    Widget label(String text) => Text(text, maxLines: 1, style: style);

    return DailyPriceLine(
      date: label('날짜'),
      close: label('종가'),
      change: label('등락'),
      volume: label('거래량'),
    );
  }
}
