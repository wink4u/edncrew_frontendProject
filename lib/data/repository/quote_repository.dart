import '../../domain/quote.dart';
import '../datasource/realtime_price_api.dart';
import '../dto/realtime_price_dto.dart';

class QuoteRepository {
  const QuoteRepository(this._api);

  final RealtimePriceApi _api;

  Future<Map<String, Quote>> fetchQuotes(List<String> symbols) async {
    final dtos = await _api.fetch(symbols);

    return {for (final dto in dtos) dto.symbol: _toQuote(dto)};
  }

  Quote _toQuote(RealtimePriceDto dto) => Quote(
    symbol: dto.symbol,
    price: dto.currentPrice,
    previousClose: dto.previousClose,
    open: dto.open,
    high: dto.high,
    low: dto.low,
    volume: dto.accumulatedVolume,
    marketCap: dto.currentPrice * dto.listedShares,
  );
}