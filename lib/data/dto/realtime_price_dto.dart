class RealtimePriceDto {
  const RealtimePriceDto({
    required this.symbol,
    required this.currentPrice,
    required this.previousClose,
    required this.open,
    required this.high,
    required this.low,
    required this.accumulatedVolume,
    required this.listedShares,
  });

  final String symbol;          // 종목코드
  final int currentPrice;       // 현재가
  final int previousClose;      // 전일 종가
  final int open;               // 시가
  final int high;               // 고가
  final int low;                // 저가
  final int accumulatedVolume;  // 누적 거래량
  final int listedShares;       // 상장 주식 수

  factory RealtimePriceDto.fromJson(Map<String, dynamic> json) {
    // json의 key를 null이 아니면 int로 변환하고 아니면 0값으로 대체
    int n(String key) => (json[key] as num?)?.toInt() ?? 0;

    return RealtimePriceDto(
        symbol: json['cd'] as String,
        currentPrice: n('nv'),
        previousClose: n('pcv'),
        open: n('ov'),
        high: n('hv'),
        low: n('lv'),
        accumulatedVolume: n('aq'),
        listedShares: n('countOfListedStock')
    );
  }
}