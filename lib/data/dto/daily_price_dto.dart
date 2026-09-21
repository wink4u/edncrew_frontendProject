class DailyPriceDto {
  const DailyPriceDto({
    required this.date,
    required this.close,
    required this.open,
    required this.high,
    required this.low,
    required this.volume,
  });

  final DateTime date;  // 날짜
  final int close;      // 종가
  final int open;       // 시가
  final int high;       // 고가
  final int low;        // 저가
  final int volume;     // 거래량

  factory DailyPriceDto.fromJson(Map<String, dynamic> json) {
    // 가격을 int로 바꿈
    int n(String key) => (json[key] as num?)?.toInt() ?? 0;

    // '20260921' 같은 8자리 문자열을 날짜로 바꿈
    final raw = json['localDate'] as String;
    if (raw.length != 8) throw FormatException('잘못된 날짜: $raw');

    return DailyPriceDto(
        date: DateTime(
          int.parse(raw.substring(0, 4)),
          int.parse(raw.substring(4, 6)),
          int.parse(raw.substring(6, 8)),
        ),
        close: n('closePrice'),
        open: n('openPrice'),
        high: n('highPrice'),
        low: n('lowPrice'),
        volume: n('accumulatedTradingVolume'),
    );

  }
}