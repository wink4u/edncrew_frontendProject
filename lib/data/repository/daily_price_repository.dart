import 'dart:math' as math;

import '../../domain/candle.dart';
import '../../domain/chart_period.dart';
import '../datasource/daily_price_api.dart';
import '../dto/daily_price_dto.dart';

// 일별 시세를 기간(1개월~1년)에 맞춰 돌려준다.
// 이미 받은 구간은 다시 요청하지 않고, 더 긴 기간이 필요하면 모자란 (더 오래된) 구간만 받는다.
// 받아 둔 값은 이 객체가 살아 있는 동안만 유지한다. (상세 화면 하나에 하나씩 만든다)
class DailyPriceRepository {
  DailyPriceRepository(this._api, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final DailyPriceApi _api;
  final DateTime Function() _now;   // 테스트에서 '오늘'을 바꿔 끼우기 위함

  // 등락을 구하려면 직전 거래일이 필요해서, 시작일보다 며칠 앞서 받는다.
  // (연휴가 겹쳐도 직전 거래일이 들어오도록 넉넉히)
  static const int leadDays = 5;

  final Map<String, _Series> _series = {};        // 종목코드 -> 받아 둔 시세
  final Map<String, Future<void>> _queue = {};    // 종목코드 -> 진행 중인 요청 줄

  // 종목의 [기간] 캔들. 오래된 날짜가 앞이다.
  Future<List<Candle>> fetchCandles(String symbol, ChartPeriod period) {
    // 같은 종목의 요청은 줄을 세운다.
    // 1년 요청이 끝나기 전에 3개월을 눌러도, 앞 요청이 끝난 뒤 이미 받은 구간임을 알아본다.
    final previous = _queue[symbol] ?? Future<void>.value();
    final run = previous.then((_) => _load(symbol, period));

    // 이 요청이 실패해도 다음 요청은 이어서 처리한다.
    _queue[symbol] = run.then<void>((_) {}, onError: (_) {});
    return run;
  }

  Future<List<Candle>> _load(String symbol, ChartPeriod period) async {
    final today = _dateOnly(_now());
    final windowStart = _monthsBefore(today, period.months);      // 화면에 보일 첫 날
    final needFrom = _daysBefore(windowStart, leadDays);          // 실제로 필요한 첫 날

    final series = _series[symbol];

    if (series == null) {
      // 처음: 필요한 구간 전체
      final rows = await _api.fetch(symbol, from: needFrom, to: today);
      _series[symbol] = _Series(rows: rows, coveredFrom: needFrom);
    } else if (needFrom.isBefore(series.coveredFrom)) {
      // 더 긴 기간: 받아 둔 구간의 바로 앞까지만 추가로 받는다.
      final older = await _api.fetch(
        symbol,
        from: needFrom,
        to: _daysBefore(series.coveredFrom, 1),
      );
      series.rows = [...older, ...series.rows];
      series.coveredFrom = needFrom;
    }
    // 이미 받은 구간이면 요청하지 않는다.

    return _toCandles(_series[symbol]!.rows, windowStart);
  }

  // 시작일 이후만 골라 캔들로 바꾼다. 바로 앞 행의 종가를 전일 종가로 붙인다.
  List<Candle> _toCandles(List<DailyPriceDto> rows, DateTime windowStart) => [
    for (var i = 0; i < rows.length; i++)
      if (!rows[i].date.isBefore(windowStart))
        Candle(
          date: rows[i].date,
          open: rows[i].open,
          high: rows[i].high,
          low: rows[i].low,
          close: rows[i].close,
          volume: rows[i].volume,
          previousClose: i > 0 ? rows[i - 1].close : null,
        ),
  ];

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime _daysBefore(DateTime d, int days) =>
      DateTime(d.year, d.month, d.day - days);

  // 달력 기준 n개월 전. 그 달에 없는 날이면 그 달의 마지막 날로 맞춘다. (3/31의 1개월 전 -> 2/28)
  DateTime _monthsBefore(DateTime d, int months) {
    final total = d.year * 12 + (d.month - 1) - months;
    final year = total ~/ 12;
    final month = total % 12 + 1;
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, math.min(d.day, lastDay));
  }
}

// 한 종목의 받아 둔 시세. rows는 오래된 날짜가 앞이다.
class _Series {
  _Series({required this.rows, required this.coveredFrom});

  List<DailyPriceDto> rows;
  DateTime coveredFrom;   // 여기부터 받아 뒀다 (요청한 시작일 기준)
}
