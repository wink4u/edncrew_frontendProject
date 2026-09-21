import 'package:flutter/material.dart';

import '../../theme/theme.dart';
import '../atoms/app_icon_button.dart';
import '../atoms/text_styles.dart';
import '../molecules/sort_chip.dart';

// 관심 화면의 헤더 component
class LikelistHeader extends StatelessWidget {
  const LikelistHeader({
    super.key,
    required this.sortLabel,    // 현재 정렬 기준을 나타냄
    required this.onSortTap,    // 정렬 탭을 누름
    required this.onRefresh,    // 시세 다시 조회 아이콘 버튼 누름
  });

  final String sortLabel;
  final VoidCallback onSortTap;
  final VoidCallback onRefresh;

  static const double _height = 52;
  static const double _refreshButtonInset = 14;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dimens = context.dimens;

    final trailingGap = dimens.space4 - _refreshButtonInset;

    return SizedBox(
      height: _height,
      child: Row(
        children: [
          SizedBox(width: dimens.space4),
          Expanded(child: Semantics(
            header: true,
            child: Text(
              '관심',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyles.headerTitle.copyWith(color: colors.textPrimary),
            )
          )),
          SortChip(label: sortLabel, onTap: onSortTap),
          SizedBox(width: trailingGap),
          AppIconButton(icon: Icons.refresh, onPressed: onRefresh, tooltip: '새로고침'),
          SizedBox(width: trailingGap),
        ],
      )
    );
  }
}