import 'package:flutter/material.dart';

import '../../theme/theme.dart';
import '../atoms/highlight_text.dart';
import '../atoms/text_styles.dart';

class StockTitleBlock extends StatelessWidget {
  const StockTitleBlock({
    super.key,
    required this.name,
    required this.subtitle,
    this.highlightQuery = '',
  });

  final String name;
  final String subtitle;
  final String highlightQuery;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      // 가로로 왼쪽 정렬
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HighlightText(
          text: name,
          query: highlightQuery,
          style: TextStyles.stockName.copyWith(color: colors.textPrimary),
        ),
        SizedBox(height: context.dimens.space1),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyles.stockSubtitle.copyWith(
            color: colors.textTertiary
          )
        )
      ]
    );
  }
}