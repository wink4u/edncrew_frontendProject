enum ChartPeriod {
  oneMonth('1개월', 1),
  threeMonths('3개월', 3),
  sixMonths('6개월', 6),
  oneYear('1년', 12);

  const ChartPeriod(this.label, this.months);

  final String label;   // 화면에 보이는 이름
  final int months;     // 오늘부터 몇 개월 전까지 보여 주는지 (달력 기준)
}
