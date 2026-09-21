import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../dto/daily_price_dto.dart';

// 종목의 날짜 구간 일별 시세를 조회함
class DailyPriceApi {
  const DailyPriceApi(this._client);

  final ApiClient _client;

  Future<List<DailyPriceDto>> fetch(
      String symbol, {
        required DateTime from, // 시작일
        required DateTime to, // 종료일
    }
  ) async {
    final url = Uri.https(
      'api.stock.naver.com',
      '/chart/domestic/item/$symbol/day',
      {
        'startDateTime': '${_ymd(from)}0000',
        'endDateTime': '${_ymd(to)}2359'
      },
    );

    final list = await _client.getJsonList(url);

    try {
      return [
        for (final item in list)
          DailyPriceDto.fromJson(item as Map<String, dynamic>)
      ];
    } on FormatException catch (e) {
      // 날짜 형식이 이상하면
      throw ApiException(ApiErrorType.parse, e.message);
    } on TypeError {
      // 필드 종류가 다를 때
      throw ApiException(ApiErrorType.parse, '일별 시세 형식이 다릅니다');
    }
  }

  String _ymd(DateTime d) =>
      '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';
}