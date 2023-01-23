dynamic g(num? i) {
  Map<int?, int> m = {0: 1};
  m[(i as int?)];

  var list = [(i as int?), (i as int?), (i as int?)];
  var list2 = [(i is int?), (i is int?), (i is int?)];
  return [list.first, list2.first];
}
