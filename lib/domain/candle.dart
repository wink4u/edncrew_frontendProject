import 'quote.dart';

// 하루치 캔들. 차트와 일별 시세 표가 함께 쓴다.
class Candle {
  const Candle({
    required this.date,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  final DateTime date;
  final int open;     // 시가
  final int high;     // 고가
  final int low;      // 저가
  final int close;    // 종가
  final int volume;   // 거래량

  // 캔들 색을 정하는 방향: 종가가 시가보다 높으면 상승, 낮으면 하락
  PriceDirection get direction => close > open
      ? PriceDirection.up
      : close < open
      ? PriceDirection.down
      : PriceDirection.flat;
}