import 'package:cp949_codec/cp949_codec.dart';

// euc-kr byte를 해독하기 위한 decoder
// dart에는 euc-kr코덱이 없기 때문에 필요함
// allowInvalid: true는 해독할 수 없는 바이트를 만났을 때 대체문자로 바꾸고 진행
String decodeEucKr(List<int> bytes) =>
    cp949.decode(bytes, allowInvalid: true);