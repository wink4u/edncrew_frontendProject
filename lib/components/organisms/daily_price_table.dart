import 'package:flutter/material.dart';

import '../../domain/candle.dart';
import '../../theme/theme.dart';
import '../atoms/text_styles.dart';
import '../molecules/daily_price_header.dart';
import '../molecules/daily_price_row.dart';

// 일별 시세 표: 제목 + 머리글 + 데이터 행들.
// candles가 null이면 로딩, 비어 있으면 빈 상태, hasError면 실패 화면.
class DailyPriceTable extends StatelessWidget {
  const DailyPriceTable({
    super.key,
    required this.candles,    // 보여 줄 캔들 (최신이 앞). null이면 로딩
    this.hasError = false,
    this.onRetry,
  });

  final List<Candle>? candles;
  final bool hasError;
  final VoidCallback? onRetry;

  static const int loadingRows = 5;
  static const double _titleGap = 4;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final candles = this.candles;

    return Column(
      mainAxisSize: MainAxisSize.min,   // 내용 높이만큼만 (ListView 안에서 쓰므로)
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            '일별 시세',
            style: TextStyles.dailyTitle.copyWith(color: colors.textPrimary),
          ),
        ),
        const SizedBox(height: _titleGap),
        const DailyPriceHeader(),
        if (hasError)
          _message(
            context,
            '일별 시세를 불러오지 못했습니다',
            action: TextButton(onPressed: onRetry, child: const Text('다시 시도')),
          )
        else if (candles == null)
          for (var i = 0; i < loadingRows; i++) const DailyPriceRow(candle: null)
        else if (candles.isEmpty)
          _message(context, '표시할 시세가 없습니다')
        else
          for (final candle in candles) DailyPriceRow(candle: candle),
      ],
    );
  }

  Widget _message(BuildContext context, String text, {Widget? action}) => Padding(
    padding: EdgeInsets.symmetric(vertical: context.dimens.space4),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: TextStyles.tableCell.copyWith(color: context.colors.textTertiary),
          ),
          if (action != null) action,
        ],
      ),
    ),
  );
}
