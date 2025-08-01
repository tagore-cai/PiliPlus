enum LiveQuality {
  dolby,
  super4K,
  origin,
  bluRay,
  superHD,
  smooth,
  flunt,
}

extension LiveQualityExt on LiveQuality {
  static const List<int> _codeList = [
    30000,
    20000,
    10000,
    400,
    250,
    150,
    80,
  ];
  int get code => _codeList[index];

  static LiveQuality? fromCode(int code) {
    final index = _codeList.indexOf(code);
    if (index != -1) {
      return LiveQuality.values[index];
    }
    return null;
  }

  String get description => const [
    '杜比',
    '4K',
    '原画',
    '蓝光',
    '超清',
    '高清',
    '流畅',
  ][index];
}
