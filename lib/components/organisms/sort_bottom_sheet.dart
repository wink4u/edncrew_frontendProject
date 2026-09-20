import 'package:flutter/material.dart';

import '../../theme/theme.dart';
import '../atoms/text_styles.dart';

// 정렬 시트의 한 줄 molecule: '현재가순' + (선택되면) 오른쪽 체크.

class SortOptionTile extends StatelessWidget {
  const SortOptionTile({
    super.key,
    required this.label,        // 정렬 기준 이름
    required this.isSelected,   // 지금 선택된 기준인지
    required this.onTap,        // 눌렀을 때
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  static const double _height = 56;      // 항목 높이 고정 56
  static const double _checkSize = 24;   // 체크 아이콘 24

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dimens = context.dimens;

    return Semantics(
      button: true,
      selected: isSelected,     // 선택됨으로 전달
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,   // 줄 전체가 눌림
        onTap: onTap,
        child: SizedBox(
          height: _height,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: dimens.space6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    // 선택되면 밝고 굵게, 아니면 회색
                    style: TextStyles.sortOption.copyWith(
                      color: isSelected ? colors.textPrimary : colors.textSecondary,
                      fontWeight: isSelected ? AppTypography.bold : AppTypography.medium,
                    ),
                  ),
                ),
                // 선택된 항목에만 체크표시 icon
                if (isSelected)
                  Icon(Icons.check, size: _checkSize, color: colors.textPrimary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}