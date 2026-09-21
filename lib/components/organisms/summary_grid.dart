import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import '../../domain/quote.dart';
import '../../theme/theme.dart';
import '../molecules/summary_card.dart';

// 카드 다섯개 설정
// 위 3개 아래 2개
class SummaryGrid extends StatelessWidget {
  const SummaryGrid({
    super.key,
    required this.quote
  });

  final Quote? quote;

  @override
  Widget build(BuildContext context) {
    final gap = context.dimens.space2;
    final quote = this.quote;

    return Column(
      children: [
        _row(gap, [
          SummaryCard(label: '시가', value: quote == null ? null : formatPrice(quote.open)),
          SummaryCard(label: '고가', value: quote == null ? null : formatPrice(quote.high)),
          SummaryCard(label: '저가', value: quote == null ? null : formatPrice(quote.low)),
        ]),
        SizedBox(height: gap),
        _row(gap, [
          SummaryCard(label: '거래량', value: quote == null ? null : formatVolume(quote.volume)),
          SummaryCard(label: '시가총액', value: quote == null ? null : formatMarketCap(quote.marketCap))
        ])
      ],
    );
  }

  // 카드들을 같은 너비로 나눠 한 줄에 놓는다.
  Widget _row(double gap, List<Widget> cards) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (var i = 0; i < cards.length; i++) ...[
        if (i > 0) SizedBox(width: gap),
        Expanded(child: cards[i]),
      ],
    ],
  );
}