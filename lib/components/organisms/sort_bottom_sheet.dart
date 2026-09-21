import 'package:flutter/material.dart';

import '../../domain/likelist_sort.dart';
import '../../theme/theme.dart';
import '../atoms/text_styles.dart';
import '../molecules/sort_option_tile.dart';

// 정렬 시트 organism: 제목 '정렬' + 항목 세 줄.
// 항목을 고르면 시트가 닫히면서 "고른 기준"을 돌려준다.
class SortBottomSheet extends StatelessWidget {
  const SortBottomSheet({super.key, required this.selected});

  final LikelistSort selected;   // 지금 선택된 정렬 기준

  static const double _radius = 16;       // 위쪽 모서리
  static const double _topInset = 1;      // Padding Top 1
  static const double _titleHeight = 64;  // 제목 영역 높이 고정 64

  // 시트를 여는 함수. 사용자가 고른 기준을 돌려주고, 그냥 닫으면 null을 돌려준다.
  static Future<LikelistSort?> show(
    BuildContext context, {
    required LikelistSort selected,
  }) {
    return showModalBottomSheet<LikelistSort>(
      context: context,
      isScrollControlled: true,   // 시트 높이를 화면 9/16으로 제한하지 않음
      backgroundColor: context.colors.surfaceOverlay,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(_radius)),
      ),
      builder: (_) => SortBottomSheet(selected: selected),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dimens = context.dimens;

    // SafeArea: 기기 아래 시스템 영역만큼 띄운다.
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(top: _topInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,          // 내용 높이만큼만
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 제목 영역: 높이 64 고정
            SizedBox(
              height: _titleHeight,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: dimens.space6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Semantics(
                    header: true,   // 화면 읽기 프로그램에 '제목'으로 알림
                    child: Text(
                      '정렬',
                      style: TextStyles.sheetTitle.copyWith(color: colors.textPrimary),
                    ),
                  ),
                ),
              ),
            ),
            // 항목 세 줄: enum의 모든 값을 순서대로
            for (final option in LikelistSort.values)
              SortOptionTile(
                label: option.label,
                isSelected: option == selected,
                // 누르면 시트를 닫으면서 그 기준을 돌려준다.
                onTap: () => Navigator.of(context).pop(option),
              ),
          ],
        ),
      ),
    );
  }
}
