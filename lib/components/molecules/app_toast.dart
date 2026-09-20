import 'package:flutter/material.dart';

import '../../theme/theme.dart';
import '../atoms/text_styles.dart';

// toast 알람 component
class AppToast extends StatelessWidget {
  const AppToast({
    super.key,
    required this.icon,     // 등록에 따라 별 상태
    required this.message,  // 문구
    this.iconColor,         // 아이콘 색
  });

  final IconData icon;
  final String message;
  final Color? iconColor;

  static const double _updownPadding = 14;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dimens = context.dimens;
    final radius = BorderRadius.circular(dimens.radiusLg);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dimens.space4,
        vertical: _updownPadding,
      ),
      decoration: BoxDecoration(color: colors.surfaceOverlay, borderRadius: radius),
      foregroundDecoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: colors.borderSubtle, width: dimens.borderHairline),
      ),
      child: Row(
        children: [
          Icon(icon, size: dimens.iconSm, color: iconColor ?? colors.textPrimary),
          SizedBox(width: dimens.space2),
          Expanded(
            child: Text(
              message,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyles.toast.copyWith(color: colors.textPrimary)
            )
          )
        ],
      )
    );
  }
}