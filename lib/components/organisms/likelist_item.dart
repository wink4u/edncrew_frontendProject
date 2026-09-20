import 'package:flutter/material.dart';

import '../../domain/quote.dart';
import '../../domain/stock.dart';
import '../../theme/theme.dart';
import '../molecules/price_summary.dart';
import '../molecules/stock_title_block.dart';

// 관심목록의 하나의 item

class LikelistItem extends StatelessWidget {
  const LikelistItem({
    super.key,
    required this.stock,
    required this.quote,
    required this.onTap,
  });

  final Stock stock;
  final Quote? quote;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dimens = context.dimens;

    return InkWell(
      onTap: onTap,
      child: Container (
        constraints: BoxConstraints(minHeight: dimens.rowMinHeight),
        padding: EdgeInsets.symmetric(horizontal: dimens.space4),
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
            Expanded(child: StockTitleBlock(name: stock.name, subtitle: stock.subtitle)),
            SizedBox(width: dimens.space3),
            PriceSummary(quote: quote)
          ],
        )
      )
    );
  }
}