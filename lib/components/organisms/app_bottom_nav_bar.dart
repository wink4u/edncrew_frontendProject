import 'package:flutter/material.dart';

import '../../theme/theme.dart';
import '../molecules/nav_item.dart';

// 하단 탭 바 organism. 탭 과 눌린 번호를 알리는 component
class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.currentIndex, // 선택된 번호
    required this.onTap,        // 탭이 눌리면 그 번호를 알림
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _tabs = [
    (icon: Icons.star_border_rounded, label: '관심'),
    (icon: Icons.search, label: '검색')
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dimens = context.dimens;

    return Container(
      color: colors.surfaceBase,

      foregroundDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: colors.borderSubtle, width: dimens.borderHairline),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: dimens.tabBarHeight,
          child: Row(
            children: [
              for (var i = 0; i < _tabs.length; i++)
                Expanded(
                  child: NavItem(
                      icon: _tabs[i].icon,
                      label: _tabs[i].label,
                      isActive: i == currentIndex,
                      onTap: () => onTap(i),
                  ),
                )
            ]
          )
        )
      )
    );
  }
}