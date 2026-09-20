enum ApiErrorType { network, timeout, http, parse }

// network 인터넷 끊김 현상
// timeout 응답 제한 시간 초과
// http 서버 상태 코드 200이 아닌 경우
// parse JSON을 읽지 못한 경우

class ApiException implements Exception {
  // 생성자
  // const로 값이 바뀌지 않는 객체로 설정
  const ApiException(this.type, this.message, {this.statusCode});

  // final은 한 번 정한 값은 바꿀 수 없을 때 사용

  final ApiErrorType type; // 실패 원인
  final String message;    // 설명 메세지
  final int? statusCode;   // null도 될 수 있으니 int?로 설정

  // 부모가 가진 toString()을 이 클래스 맞게 다시 정의
  @override
  // => js의 화살표 함수처럼 활용됨. 오른쪽이 반환값이라 return을 쓰지 않음
  String toString() => 'ApiException($type, $message, status: $statusCode)';
}