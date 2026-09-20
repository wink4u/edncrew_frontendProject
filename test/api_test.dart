import 'package:edencrew_assignment_starter/core/network/api_client.dart';
import 'package:edencrew_assignment_starter/data/datasource/search_autocomplete_api.dart';
import 'package:edencrew_assignment_starter/data/datasource/realtime_price_api.dart';
import 'package:edencrew_assignment_starter/data/datasource/stock_metadata_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final client = ApiClient();

  test('삼성전자를 검색하면 005930이 확인된다', () async {
    final items = await SearchAutocompleteApi(client).search('삼성전자');
    expect(items.any((i) => i.code == '005930'), isTrue);
  });

  test('실시간 시세: 2종목이 요청 1번에 온다', () async {
    final items = await RealtimePriceApi(client).fetch(['005930', '000660']);
    expect(items.map((i) => i.symbol), containsAll(['005930', '000660']));
  });

  test('메타: 005930은 삼성전자 / 코스피 인가', () async {
    final meta = await StockMetadataApi(client).fetch('005930');
    expect(meta.stockName, '삼성전자');
    expect(meta.exchangeNameKor, '코스피');
  });
}