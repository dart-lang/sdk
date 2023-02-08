test1(dynamic x) {
  for (var [int y] in x) {
    if (y % 10 == 0) {
      return y;
    }
  }
  return -1;
}

test2(Iterable<List<String>> x) {
  for (var [..., String y] in x) {
    if (y.startsWith("f")) {
      return y;
    }
  }
  return "";
}

test3(Iterable<dynamic> x) {
  for (var [int y, ...] in x) {
    return y;
  }
  return -1;
}

main() {
  expectEquals(test1([[1], [2], [3]]), -1);
  expectEquals(test1([[1], [2], [30]]), 30);
  expectEquals(test2([["foo", "bar", "baz"], ["bar", "foo", "baz"], ["bar", "baz", "foo"]]), "foo");
  expectEquals(test2([]), "");
  expectThrows(() => test3([[null, 1, 2]]));
  expectEquals(test3([]), -1);
}

expectEquals(x, y) {
  if (x != y) {
    throw "Expected '${x}' to be equal to '${y}'.";
  }
}

expectThrows(void Function() f) {
  bool hasThrown = true;
  try {
    f();
    hasThrown = false;
  } catch (e) {}
  if (!hasThrown) {
    throw "Expected function to throw.";
  }
}
