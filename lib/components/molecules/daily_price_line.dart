import 'package:flutter/material.dart';

import '../../theme/theme.dart';

// 일별 시세 표의 한 줄 틀: 날짜(왼쪽) + 종가, 등락, 거래량(오른쪽 정렬, 같은 너비).
// 위아래 패딩 7, 아래 1px 구분선. 머리글과 데이터 행이 같이 쓴다.
class DailyPriceLine extends StatelessWidget {
  const DailyPriceLine({
    super.key,
    required this.date,
    required this.close,
    required this.change,
    required this.volume,
  });

  final Widget date;
  final Widget close;
  final Widget change;
  final Widget volume;

  static const double dateWidth = 44;       // TODO(figma): 날짜 칸 너비
  static const double columnGap = 8;
  static const double verticalPadding = 7;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dimens = context.dimens;
    const gap = SizedBox(width: columnGap);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: verticalPadding),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: colors.borderSubtle, width: dimens.borderHairline),
        ),
      ),
      child: Row(
        children: [
          SizedBox(width: dateWidth, child: Align(alignment: Alignment.centerLeft, child: date)),
          gap,
          Expanded(child: Align(alignment: Alignment.centerRight, child: close)),
          gap,
          Expanded(child: Align(alignment: Alignment.centerRight, child: change)),
          gap,
          Expanded(child: Align(alignment: Alignment.centerRight, child: volume)),
        ],
      ),
    );
  }
}
