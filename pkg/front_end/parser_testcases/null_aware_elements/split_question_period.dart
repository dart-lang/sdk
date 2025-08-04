// dart format off
test1() {
  return <int>[
    ? .tryParse("a"),
    ? .tryParse("1"),
  ];
}

test2() {
  return <int>{
    ? .tryParse("a"),
    ? .tryParse("1"),
  };
}

test3() {
  return <int, int>{
    ? .tryParse("a"): 0,
    0: ? .tryParse("a"),
    ? .tryParse("0"): ? .tryParse("a"),
    ? .tryParse("a"): ? .tryParse("0"),
    ? .tryParse("1"): ? .tryParse("1"),
  };
}
