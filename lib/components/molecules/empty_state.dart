import 'package:flutter/material.dart';

import '../../theme/theme.dart';
import '../atoms/text_styles.dart';

// 앱의 가운데에 관심, 검색 결과 없음에 사용
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.action,   // 아래에 붙일 위젯(버튼 등). 없어도 됨
  });

  final IconData icon;
  final String title;
  final String description;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dimens = context.dimens;
    // 필드는 null 검사가 통하지 않아서 지역 변수로 복사한다.
    final action = this.action;

    // 남는 공간의 가운데에 넣기위한 Center
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: dimens.space6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: dimens.iconLg, color: colors.textSecondary),
            SizedBox(height: dimens.space3),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyles.emptyTitle.copyWith(color: colors.textSecondary)
            ),
            SizedBox(height: dimens.space3),
            Text(
              description,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyles.emptySubtitle.copyWith(color: colors.textTertiary),
            ),
            // 버튼 같은 위젯이 있을 때만 간격과 함께 추가
            if (action != null) ...[
              SizedBox(height: dimens.space4),
              action,
            ],
          ],
        )
      )
    );
  }
}