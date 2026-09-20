import 'package:flutter/material.dart';

import '../../domain/stock.dart';
import '../../theme/theme.dart';
import '../atoms/star_button.dart';
import '../molecules/stock_title_block.dart';

// 검색 결과 목록 component
class SearchResultTitle extends StatelessWidget {
  const SearchResultTitle({
    super.key,
    required this.stock,              // 종목
    required this.query,              // 강조 검색어
    required this.isFavorite,         // 관심 등록상태
    required this.onTap,              // stock을 누를 때
    required this.onFavoritePressed,  // 별을 눌렀을 때
  });

  final Stock stock;
  final String query;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoritePressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dimens = context.dimens;

    // InkWell은 물결 효과 및 탭 입식
    return InkWell(
      onTap: onTap,
      child: Container(
        // 높이 고정하지 않음
        constraints: BoxConstraints(minHeight: dimens.rowMinHeight),
        padding: EdgeInsets.only(left: dimens.space4, right: dimens.space4),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: colors.borderSubtle,
              width: dimens.borderHairline,
            )
          )
        ),
        child: Row(
          children: [
            Expanded(
              child: StockTitleBlock(
                name: stock.name,
                subtitle: stock.subtitle,
                highlightQuery: query,
              )
            ),
            StarButton(isActive: isFavorite, onPressed: onFavoritePressed),
          ]
        )

      )
    );
  }
}