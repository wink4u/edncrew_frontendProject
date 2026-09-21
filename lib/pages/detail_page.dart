import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../components/atoms/text_styles.dart';
import '../components/molecules/candle_chart.dart';
import '../components/molecules/detail_price_summary.dart';
import '../components/molecules/empty_state.dart';
import '../components/molecules/toast_snack_bar.dart';
import '../components/organisms/daily_price_table.dart';
import '../components/organisms/detail_header.dart';
import '../components/organisms/period_tab_bar.dart';
import '../components/organisms/summary_grid.dart';
import '../core/network/api_client.dart';
import '../data/datasource/daily_price_api.dart';
import '../data/repository/daily_price_repository.dart';
import '../data/repository/quote_repository.dart';
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
        // 받아 둔 캔들이 이 화면과 함께 사라지도록 화면마다 새로 만든다.
        dailyPrices: DailyPriceRepository(
          DailyPriceApi(context.read<ApiClient>()),
        ),
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
        const _ChartArea(),
        SizedBox(height: dimens.space4),         // TODO(figma): 차트와 카드 사이 간격
        SummaryGrid(quote: detail.quote),
        SizedBox(height: dimens.space6),   // 24
        const _DailyTableArea(),
      ],
    );
  }
}

// 일별 시세 표 자리: 받았으면 표, 실패면 다시 시도, 아직이면 스켈레톤
class _DailyTableArea extends StatelessWidget {
  const _DailyTableArea();

  @override
  Widget build(BuildContext context) {
    final detail = context.watch<DetailNotifier>();

    return DailyPriceTable(
      candles: detail.hasRecentCandles ? detail.recentCandles : null,
      hasError: detail.recentCandlesError != null && !detail.hasRecentCandles,
      onRetry: () => detail.loadCandles(ChartPeriod.oneMonth),
    );
  }
}

// 차트 자리: 받았으면 차트, 실패했으면 다시 시도, 아직이면 로딩
class _ChartArea extends StatelessWidget {
  const _ChartArea();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final detail = context.watch<DetailNotifier>();

    if (detail.hasCandles) return CandleChart(candles: detail.candles);

    // 차트와 같은 높이를 유지해서 아래 요소가 움직이지 않게 한다.
    return SizedBox(
      height: CandleChart.height,
      child: Center(
        child: detail.candlesError == null
            ? CircularProgressIndicator(color: colors.accentDefault)
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '차트를 불러오지 못했습니다',
                    style: TextStyles.emptySubtitle.copyWith(color: colors.textTertiary),
                  ),
                  TextButton(
                    onPressed: detail.loadCandles,
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
      ),
    );
  }
}
