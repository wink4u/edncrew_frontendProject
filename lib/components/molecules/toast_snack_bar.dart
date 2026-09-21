import 'package:flutter/material.dart';

import '../../theme/theme.dart';
import 'app_toast.dart';

// 화면 아래에 AppToast를 잠깐 띄운다. (SnackBar를 투명하게 만들고 그 안에 AppToast를 넣는 방식)
void showToast(
  BuildContext context, {
  required IconData icon,
  required String message,
  Color? iconColor,
}) {
  final dimens = context.dimens;

  ScaffoldMessenger.of(context)
    ..removeCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        margin: EdgeInsets.fromLTRB(dimens.space4, 0, dimens.space4, dimens.space2),
        duration: const Duration(seconds: 2),
        content: AppToast(icon: icon, iconColor: iconColor, message: message),
      ),
    );
}
