// 관심, 검색, 상세 화면 종목을 다루기 때문에 만든 stock
// 변하지 않는 값을 정리
class Stock {
  const Stock({
    required this.symbol,
    required this.name,
    required this.market
  });

  final String symbol;
  final String name;
  final String market;

  String get id => 'domestic:$symbol';
  String get subtitle => '$symbol · $market';
}