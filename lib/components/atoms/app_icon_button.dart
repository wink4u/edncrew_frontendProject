import 'package:flutter/material.dart';
import '../../theme/theme.dart';

class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,       // 아이콘 종류
    required this.onPressed,  // 눌럿을 때 상호작용
    required this.tooltip,    // 문구
    this.color,               // 색
    this.size,                // 크기
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;
  final Color? color;
  final double? size;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon),
      color: color ?? context.colors.textSecondary,
      iconSize: size ?? context.dimens.iconMd,
    );
  }
}