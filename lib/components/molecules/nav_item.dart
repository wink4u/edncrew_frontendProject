import 'package:flutter/material.dart';

import '../../theme/theme.dart';
import '../atoms/text_styles.dart';

// 하단 탭 아이콘 + 레벨, 선택 여부에 따라 색 바뀜.
class NavItem extends StatelessWidget {
  const NavItem({
    super.key,
    required this.icon,       // 탭 아이콘
    required this.label,      // 탭 이름
    required this.isActive,   // 선택된 탭
    required this.onTap,      // 탭 눌렀을 때
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dimens = context.dimens;

    final activeColor = isActive ? colors.navActive : colors.navInactive;

    return Semantics(
      button: true,
      selected: isActive,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        // 아이콘 밖의 빈 곳도 터치로 인식
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: dimens.iconMd, color: activeColor),
            SizedBox(height: dimens.space1),
            Text(label, style: TextStyles.stockSubtitle.copyWith(color: activeColor))
          ]
        )
      )
    );
  }
}