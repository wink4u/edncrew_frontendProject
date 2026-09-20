import 'package:flutter/material.dart';

import '../../theme/theme.dart';
import '../atoms/text_styles.dart';

// 검색 입력창 molecule
class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.onSubmitted,
    this.hintText = '종목명 또는 종목코드',
    this.autofocus = false,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;
  final String hintText;
  final bool autofocus;

  // 지우기
  void _clear() {
    controller.clear();
    onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dimens = context.dimens;

    // 입력한 글자
    final inputStyle = TextStyles.stockName.copyWith(color: colors.textPrimary);
    final radius = BorderRadius.circular(dimens.radiusMd); // 8

    return Container(
      height: 40,
      padding: EdgeInsets.only(left: dimens.space3, right: dimens.space1),
      // 배경
      decoration: BoxDecoration(color: colors.surfaceSunken, borderRadius: radius),
      foregroundDecoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(
          color: colors.borderStrong,
          width: dimens.borderHairline
        )
      ),
      child: Row(
        children: [
          // 돋보기: 16
          Icon(Icons.search, size: dimens.iconSm, color: colors.textTertiary),
          SizedBox(width: dimens.space2), // Gap 값 8
          Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                onSubmitted: onSubmitted,
                autofocus: autofocus,
                // 검색 값
                textInputAction: TextInputAction.search,
                style: inputStyle,
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  // 플레이스 홀더 설정
                  hintText: hintText,
                  hintStyle: inputStyle.copyWith(color: colors.textTertiary)
                ),
              )
          ),

          Semantics(
            button: true,
            label: '검색어 지우기',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _clear,
              child: Padding(
                padding: EdgeInsets.all(dimens.space2),
                child: Icon(Icons.close, size: dimens.iconSm, color: colors.textTertiary),
              )
            )
          )
        ],
      )
    );
  }
}