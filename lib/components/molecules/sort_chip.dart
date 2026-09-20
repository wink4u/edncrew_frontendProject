import 'package:flutter/material.dart';

import '../../theme/theme.dart';
import '../atoms/text_styles.dart';

// 정렬 칩 molecule: 헤더의 '가나다순 ↓'. 눌러서 정렬 시트를 여는 버튼 역할.
class SortChip extends StatelessWidget {
  const SortChip({
    super.key,
    required this.label,  // '가나다 순'
    required this.onTap,  // 누를 때 바텀 시트 open
  });

  final String label;
  final VoidCallback onTap;

  static const double _arrowGap = 6;
  static const double _tapPaddingVertical = 10;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dimens = context.dimens;

    return Semantics(
      button: true,
      label: '정렬 기준 $label',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: _tapPaddingVertical),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                maxLines: 1,
                style: TextStyles.sortChip.copyWith(color: colors.textSecondary),
              ),
              const SizedBox(width: _arrowGap),
              Icon(Icons.arrow_downward, size: dimens.iconMd, color: colors.textSecondary),
            ],
          )
        )
      )
    );
  }
}