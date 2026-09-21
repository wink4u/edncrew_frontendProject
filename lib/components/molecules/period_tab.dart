import 'package:flutter/material.dart';

import '../../theme/theme.dart';
import '../atoms/text_styles.dart';

// 기간 탭 한개
class PeriodTab extends StatelessWidget {
  const PeriodTab({
    super.key,
    required this.label,
    required this.isSelected,   // 눌린 상태확인
    required this.onTap,        // 눌렸을 때 바뀌는 함수 설정
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  static const double _verticalPadding = 5;
  static const double _horizontalPdding = 12;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final radius = BorderRadius.circular(context.dimens.radiusMd);

    return Semantics(
      button: true,
      selected: isSelected,
      child: Material(
        color: isSelected ? colors.accentBg : Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: _verticalPadding,
              horizontal: _horizontalPdding,
            ),
            child: Center(
              child: Text(
                label,
                maxLines: 1,
                style: TextStyles.periodTab.copyWith(
                  color: isSelected ? colors.accentDefault : colors.textSecondary
                ),
              )
            )
          )
        )
      )
    );
  }
}