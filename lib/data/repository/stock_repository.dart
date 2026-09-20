import '../../domain/stock.dart';
import '../datasource/stock_metadata_api.dart';

class StockRepository {
  StockRepository(this._api);

  final StockMetadataApi _api;

  // 캐시 저장소
  final _cache = <String, Stock>{};

  Future<Stock> getStock(String symbol) async {
    // 이미 있는 종목이면 return
    final cached = _cache[symbol];
    if (cached != null) return cached;

    // 그렇지 않다면 서버에 요청
    final meta = await _api.fetch(symbol);

    // Stock으로 바꿔 캐시 저장
    return _cache[symbol] = Stock(
      symbol: meta.symbolCode,
      name: meta.stockName,
      market: meta.exchangeNameKor,
    );
  }
}