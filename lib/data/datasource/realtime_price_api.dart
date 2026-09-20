import '../../core/network/api_client.dart';
import '../dto/realtime_price_dto.dart';

class RealtimePriceApi {
  const RealtimePriceApi(this._client);

  final ApiClient _client;

  Future<List<RealtimePriceDto>> fetch(List<String> symbols) async {
    if (symbols.isEmpty) return const [];

    final uri = Uri.https('polling.finance.naver.com', '/api/realtime',
      {'query': 'SERVICE_ITEM>:${symbols.join(',')}'});

    final json = await _client.getJson(uri, eucKr: true);

    // 응답구조에 따른 설정
    final areas = (json['result']?['areas'] as List<dynamic>?) ?? const [];

    return [
      for (final area in areas)
        for (final data in (area['datas'] as List<dynamic>? ?? const []))
          RealtimePriceDto.fromJson(data as Map<String, dynamic>)
    ];
  }
}