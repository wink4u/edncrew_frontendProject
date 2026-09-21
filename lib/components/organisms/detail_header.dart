import 'package:flutter/material.dart';

import '../../domain/stock.dart';
import '../../theme/theme.dart';
import '../atoms/app_icon_button.dart';
import '../atoms/star_button.dart';
import '../molecules/stock_title_block.dart';

// 종목 상세 화면의 헤더 organism: 뒤로 가기 + 종목명/코드 · 시장 + 관심 별
class DetailHeader extends StatelessWidget {
  const DetailHeader({
    super.key,
    required this.stock,                // 종목
    required this.isFavorite,           // 관심 등록 상태
    required this.onBack,               // 뒤로 가기를 눌렀을 때
    required this.onFavoritePressed,    // 별을 눌렀을 때
  });

  final Stock stock;
  final bool isFavorite;
  final VoidCallback onBack;
  final VoidCallback onFavoritePressed;

  static const double _minHeight = 55;      // Hug 55
  static const double _verticalPadding = 10;
  static const double _backInset = 12;      // 20px 화살표 양옆 여백 (터치 영역 44)

  @override
  Widget build(BuildContext context) {
    final dimens = context.dimens;

    // 화살표 왼쪽 여백 16, 화살표와 종목명 사이 12를 맞추기 위해
    // 터치 영역을 (아이콘 20 + 12*2 = 44)로 줄이고 바깥 여백을 16 - 12 = 4로 둔다.
    final backButtonWidth = dimens.iconMd + _backInset * 2;

    return Container(
      constraints: const BoxConstraints(minHeight: _minHeight),
      padding: const EdgeInsets.symmetric(vertical: _verticalPadding),
      child: Row(
        children: [
          SizedBox(width: dimens.space4 - _backInset),
          AppIconButton(
            icon: Icons.arrow_back,
            onPressed: onBack,
            tooltip: '뒤로 가기',
            constraints: BoxConstraints.tightFor(width: backButtonWidth, height: 48),
          ),
          Expanded(
            child: StockTitleBlock(name: stock.name, subtitle: stock.subtitle),
          ),
          StarButton(isActive: isFavorite, onPressed: onFavoritePressed),
          SizedBox(width: dimens.space4),
        ],
      ),
    );
  }
}
