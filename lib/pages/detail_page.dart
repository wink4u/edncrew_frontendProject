import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../components/molecules/candle_chart.dart';
import '../components/molecules/detail_price_summary.dart';
import '../components/molecules/empty_state.dart';
import '../components/molecules/toast_snack_bar.dart';
import '../components/organisms/detail_header.dart';
import '../components/organisms/period_tab_bar.dart';
import '../components/organisms/summary_grid.dart';
import '../data/repository/quote_repository.dart';
import '../domain/candle.dart';
import '../domain/chart_period.dart';
import '../domain/stock.dart';
import '../state/detail_notifier.dart';
import '../state/favorite_notifier.dart';
import '../theme/theme.dart';

// 종목 상세 화면. 관심, 검색 화면에서 종목을 누르면 열린다.
class DetailPage extends StatelessWidget {
  const DetailPage({super.key});

  // 화면 이동 경로. 이 종목만을 위한 DetailNotifier를 이 화면에 붙여서 넘긴다.
  static Route<void> route(Stock stock) => MaterialPageRoute<void>(
    builder: (context) => ChangeNotifierProvider<DetailNotifier>(
      create: (context) => DetailNotifier(
        stock: stock,
        quotes: context.read<QuoteRepository>(),
      ),
      child: const DetailPage(),
    ),
  );

  void _onFavoritePressed(BuildContext context, Stock stock) {
    final colors = context.colors;
    final added = context.read<FavoriteNotifier>().toggle(stock);

    showToast(
      context,
      icon: added ? Icons.star_rounded : Icons.star_border_rounded,
      iconColor: added ? colors.favoriteActive : null,
      message: added ? '관심이 등록되었습니다' : '관심이 해제되었습니다',
    );
  }

  @override
  Widget build(BuildContext context) {
    final stock = context.read<DetailNotifier>().stock;
    // 이 종목의 관심 여부가 바뀔 때만 헤더를 다시 그린다.
    final isFavorite = context.select<FavoriteNotifier, bool>(
      (favorites) => favorites.isFavorite(stock.id),
    );

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            DetailHeader(
              stock: stock,
              isFavorite: isFavorite,
              onBack: () => Navigator.of(context).pop(),
              onFavoritePressed: () => _onFavoritePressed(context, stock),
            ),
            const Expanded(child: _DetailBody()),
          ],
        ),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody();

  @override
  Widget build(BuildContext context) {
    final dimens = context.dimens;
    final detail = context.watch<DetailNotifier>();

    // 시세를 한 번도 못 받고 실패했을 때만 오류 화면. (받은 뒤 실패면 기존 값을 유지)
    if (detail.error != null && detail.quote == null) {
      return EmptyState(
        icon: Icons.error_outline_rounded,
        title: '시세를 불러오지 못했습니다',
        description: '잠시 후 다시 시도해 주세요.',
        action: TextButton(onPressed: detail.load, child: const Text('다시 시도')),
      );
    }

    // 뒤에 기간 탭, 차트, 요약 카드, 일별 시세 표가 이어지므로 ListView로 둔다.
    return ListView(
      padding: EdgeInsets.fromLTRB(dimens.space4, dimens.space2, dimens.space4, dimens.space4),
      children: [
        DetailPriceSummary(quote: detail.quote),
        SizedBox(height: dimens.space4),
        PeriodTabBar(selected: detail.period, onSelected: detail.setPeriod),
        SizedBox(height: dimens.space4),
        CandleChart(candles: _sampleCandles(detail.period)),   // TODO: 일별 시세 연결 시 실제 데이터로 교체
        SizedBox(height: dimens.space4),         // TODO(figma): 차트와 카드 사이 간격
        SummaryGrid(quote: detail.quote),
      ],
    );
  }
}


// TODO: 일별 시세를 연결하면 삭제. 기간마다 캔들 개수만 다르게 만든 가짜 데이터.
List<Candle> _sampleCandles(ChartPeriod period) {
  final count = switch (period) {
    ChartPeriod.oneMonth => 20,
    ChartPeriod.threeMonths => 60,
    ChartPeriod.sixMonths => 120,
    ChartPeriod.oneYear => 245,
  };
  final random = math.Random(7);   // 같은 값이 나오게 씨앗을 고정
  var price = 170000;

  return [
    for (var i = 0; i < count; i++)
      () {
        final open = price;
        final close = open + random.nextInt(6000) - 3000;
        final high = math.max(open, close) + random.nextInt(2500);
        final low = math.min(open, close) - random.nextInt(2500);
        price = close;
        return Candle(
          date: DateTime(2026, 1, 1).add(Duration(days: i)),
          open: open, high: high, low: low, close: close, volume: 1000,
        );
      }(),
  ];
}
