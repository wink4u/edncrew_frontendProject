// 종목의 시세 변화를 뜻하는 enum
enum PriceDirection { up, down, flat }

// 종목에서 바뀌는것들
class Quote {
  const Quote({
    required this.symbol,
    required this.price,
    required this.previousClose,
    required this.open,
    required this.high,
    required this.low,
    required this.volume,
    required this.marketCap,
  });

  final String symbol;
  final int price;
  final int previousClose;
  final int open;
  final int high;
  final int low;
  final int volume;
  final int marketCap;

  // 현재가 - 전일 증가, 양수 음수를 판단
  int get change => price - previousClose;
  // 얼마나 차이나는지 확인하는 변수
  double get changeRate =>
      previousClose == 0 ? 0 : change / previousClose * 100;

  PriceDirection get direction => change > 0 ?
      PriceDirection.up :
      change < 0 ?
          PriceDirection.down :
          PriceDirection.flat;
}