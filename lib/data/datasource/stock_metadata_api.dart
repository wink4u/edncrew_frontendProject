import '../../core/network/api_client.dart';
import '../dto/stock_metadata_dto.dart';

class StockMetadataApi {
  const StockMetadataApi(this._client);

  final ApiClient _client;

  Future<StockMetadataDto> fetch(String symbol) async {
    final uri = Uri.https(
      'stock.naver.com',
      './api/securityFe/api/fchart/domestic/stock/$symbol'
    );

    return StockMetadataDto.fromJson(await _client.getJson(uri));
  }
}