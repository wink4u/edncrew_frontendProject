enum ChartPeriod {
  oneMonth('1개월'),
  threeMonths('3개월'),
  sixMonths('6개월'),
  oneYear('1년');

  const ChartPeriod(this.label);

  final String label;   // 화면에 보이는 이름
}