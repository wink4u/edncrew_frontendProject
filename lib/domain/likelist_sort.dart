enum LikelistSort {
  price('현재가순'),
  changeRate('등락률순'),
  name('가나다순');

  const LikelistSort(this.label);

  final String label;   // 화면에 보이는 이름
}
