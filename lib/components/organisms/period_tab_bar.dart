import 'package:flutter/material.dart';

import '../../domain/chart_period.dart';
import '../molecules/period_tab.dart';

// 기간 탭 네 개를 나눔
class PeriodTabBar extends StatelessWidget {
  const PeriodTabBar({
    super.key,
    required this.selected,   // 선택된 기간
    required this.onSelected, // 탭을 눌렀을 때 알리는 함수
  });

  final ChartPeriod selected;
  final ValueChanged<ChartPeriod> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final period in ChartPeriod.values)
          Expanded(
            child: PeriodTab(
              label: period.label,
              isSelected: period == selected,
              onTap: () => onSelected(period),
            )
          )
      ],
    );
  }
}