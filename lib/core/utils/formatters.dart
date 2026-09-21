// 숫자를 화면에 보여줄 글자로 바꾸는 함수 모음.
// 화면(위젯)도 네트워크도 모르는 순수 함수라서, 값만 넣으면 항상 같은 결과가 나온다.

/// 세 자리마다 쉼표를 붙인다.  179700 → '179,700'
String formatPrice(int value) {
  final digits = value.abs().toString();           // 부호를 뺀 숫자 글자: '179700'
  final buffer = StringBuffer(value < 0 ? '-' : '');   // 글자를 이어 붙이는 도구

  for (var i = 0; i < digits.length; i++) {
    // "남은 자릿수"가 3의 배수가 되는 자리 앞에 쉼표를 넣는다. (맨 앞은 제외)
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// 등락액. 상승은 '+', 하락은 '-', 보합은 부호 없이 '0'.
///  8500 → '+8,500' / -400 → '-400' / 0 → '0'
String formatChange(int change) {
  if (change == 0) return '0';

  final sign = change > 0 ? '+' : '-';
  return '$sign${formatPrice(change.abs())}';
}

/// 등락률(퍼센트 단위). 소수 둘째 자리까지, 부호를 붙인다.
///  2.36 → '+2.36%' / -0.22 → '-0.22%' / 0 → '0.00%'
String formatChangeRate(double rate) {
  final fixed = rate.abs().toStringAsFixed(2);     // 절댓값을 소수 둘째 자리로 반올림

  // 반올림하면 0.00이 되는 값은 부호 없이 보여준다. ('-0.00%' 방지)
  if (fixed == '0.00') return '0.00%';

  return '${rate > 0 ? '+' : '-'}$fixed%';
}

/// 화면에 나오는 한 덩어리.  (8500, 2.36) → '+8,500 (+2.36%)'
String formatChangeWithRate(int change, double rate) =>
    '${formatChange(change)} (${formatChangeRate(rate)})';

/// 상세 화면의 등락. 금액에는 부호를 붙이지 않고 등락률에만 붙인다.
///  (-400, -0.22) → '400 (-0.22%)' / (0, 0) → '0 (0.00%)'
String formatDetailChange(int change, double rate) =>
    '${formatPrice(change.abs())} (${formatChangeRate(rate)})';
