import 'package:flutter/material.dart';

import '../data/repository/daily_price_repository.dart';
import '../data/repository/quote_repository.dart';
import '../domain/candle.dart';
import '../domain/chart_period.dart';
import '../domain/quote.dart';
import '../domain/stock.dart';

// 종목 상세 화면의 상태: 이 종목의 시세, 기간별 캔들, 불러오는 중, 실패 원인.
// 화면이 열릴 때 만들어지고 화면이 닫히면 함께 사라진다.
class DetailNotifier extends ChangeNotifier {
  DetailNotifier({
    required this.stock,
    required QuoteRepository quotes,
    required DailyPriceRepository dailyPrices,
  }) : _quoteRepository = quotes,
       _dailyPrices = dailyPrices {
    load();
    loadCandles();   // 처음 기간(1개월)의 캔들
  }

  final Stock stock;
  final QuoteRepository _quoteRepository;
  final DailyPriceRepository _dailyPrices;

  Quote? _quote;
  ChartPeriod _period = ChartPeriod.oneMonth;   // 처음에는 1개월
  bool _isLoading = false;
  Object? _error;

  // 캔들은 기간별로 따로 담는다.
  // 탭을 오가도 이미 받은 기간은 바로 보여 주고, 늦게 온 응답이 다른 탭의 값을 덮어쓰지 않는다.
  final Map<ChartPeriod, List<Candle>> _candles = {};
  final Map<ChartPeriod, Object> _candleErrors = {};
  final Set<ChartPeriod> _loadingPeriods = {};

  int _requestId = 0;       // 오래된 응답을 가려내는 번호
  bool _disposed = false;   // 화면이 닫힌 뒤에 notify하지 않기 위해

  Quote? get quote => _quote;
  ChartPeriod get period => _period;
  bool get isLoading => _isLoading;
  Object? get error => _error;

  // 지금 선택된 기간의 캔들
  List<Candle> get candles => _candles[_period] ?? const [];
  bool get hasCandles => _candles.containsKey(_period);   // 받았는지 (비어 있어도 받은 것)
  Object? get candlesError => _candleErrors[_period];

  // 기간 탭을 눌렀을 때. 같은 탭이면 아무것도 하지 않는다.
  void setPeriod(ChartPeriod period) {
    if (period == _period) return;
    _period = period;
    notifyListeners();
    loadCandles();
  }

  // 선택된 기간의 캔들을 불러온다.
  // 이미 받았거나 받는 중이면 아무것도 하지 않는다. 실패 뒤 '다시 시도'에도 쓴다.
  Future<void> loadCandles() async {
    final period = _period;
    if (_candles.containsKey(period) || _loadingPeriods.contains(period)) return;

    _loadingPeriods.add(period);
    _candleErrors.remove(period);

    try {
      _candles[period] = await _dailyPrices.fetchCandles(stock.symbol, period);
    } catch (error, stackTrace) {
      debugPrint('캔들 조회 실패: $error\n$stackTrace');
      _candleErrors[period] = error;
    }

    _loadingPeriods.remove(period);
    notifyListeners();
  }

  // 처음 진입, 다시 시도 모두 이 함수를 쓴다.
  Future<void> load() async {
    final requestId = ++_requestId;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _quoteRepository.fetchQuotes([stock.symbol]);
      if (_disposed || requestId != _requestId) return;

      // 응답에 이 종목이 없으면 실패로 본다.
      _quote = result[stock.symbol] ?? (throw StateError('시세 없음: ${stock.symbol}'));
    } catch (error, stackTrace) {
      if (_disposed || requestId != _requestId) return;
      debugPrint('상세 시세 조회 실패: $error\n$stackTrace');
      _error = error;
    }

    _isLoading = false;
    notifyListeners();
  }

  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
