class StockMetadataDto {
  const StockMetadataDto({
    required this.symbolCode,
    required this.stockName,
    required this.exchangeNameKor,
  });

  final String symbolCode;      // 종목코드
  final String stockName;       // 종목명
  final String exchangeNameKor; // 거래소명(한글)

  factory StockMetadataDto.fromJson(Map<String, dynamic> json) =>
      StockMetadataDto(
        symbolCode: json['symbolCode'] as String,
        stockName: json['stockName'] as String,
        exchangeNameKor: json['stockExchangeNameKor'] as String? ?? '',
  );

}