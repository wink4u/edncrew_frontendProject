import 'dart:async';      // 비동기, timeout에 활용
import 'dart:convert';    // utf8, jsonDecode에 활용
import 'dart:typed_data'; // Uint8List 바이트 배열

import 'package:http/http.dart' as http;

import 'api_exception.dart';
import 'euc_kr_decoder.dart';

class ApiClient {
  ApiClient({http.Client? client, this.timeout = const Duration(seconds: 30)})
      : _client = client ?? http.Client();

  // _로 시작하면 이 파일 안에서만 접근이 가능함
  final http.Client _client;
  final Duration timeout;

  static const _headers = {
    'User-Agent':
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/120.0 Safari/537.36',
    // 붙어 있는 문자열은 자동으로 이어진다
    'Referer': 'https://finance.naver.com/',
  };


  // async: await활용 가능 및 반환값이 자동으로 Future에 담긴다.
  Future<Uint8List> getBytes(Uri uri) async {
    try {
      final response = await _client.get(uri, headers: _headers).timeout(
          timeout);

      if (response.statusCode != 200) {
        throw ApiException(
            ApiErrorType.http,
            'HTTP ${response.statusCode}: $uri',
            statusCode: response.statusCode);
      }

      return response.bodyBytes;
    } on TimeoutException {
      // 시간 초과
      throw ApiException(ApiErrorType.timeout, 'Timeout: $uri');
    } on http.ClientException catch (e) {
      // 연결 실패
      throw ApiException(ApiErrorType.network, e.message);
    }
  }
  // euc 기본값은 false
  // Map<string, dynamic> 키는 문자열, 밸류는 뭐든 될 수 있는 것
  Future<Map<String, dynamic>> getJson(Uri uri, {bool eucKr = false}) async {
    final bytes = await getBytes(uri);

    try {
      // eucKr이면 decoder 활성
      final text = eucKr ? decodeEucKr(bytes) : utf8.decode(bytes);

      return jsonDecode(text) as Map<String, dynamic>;
    } on FormatException catch(e){
      // JSON 문법이 틀렸을 때
      throw ApiException(ApiErrorType.parse, 'Invalid JSON: ${e.message}');
    }
  }

  // 최상위가 배열([])인 JSON 응답용
  Future<List<dynamic>> getJsonList(Uri uri) async {
    final bytes = await getBytes(uri);

    try {
      return jsonDecode(utf8.decode(bytes)) as List<dynamic>;
    } on FormatException catch (e) {
      // JSON 문법이 틀렸을 때
      throw ApiException(ApiErrorType.parse, 'Invalid JSON: ${e.message}');
    } on TypeError {
      // 문법은 맞지만 배열이 아닐 때 ({}가 온 경우 등)
      throw ApiException(ApiErrorType.parse, 'JSON 배열이 아닙니다: $uri');
    }
  }
}


