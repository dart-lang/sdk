// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

Iterable<dynamic> test1(dynamic x, dynamic another) {
  return {for (var [int i, int n] = x; i < n; i++) ...another};
}

Iterable<dynamic> test2(dynamic x, dynamic another) {
  return {if (x case String _) ...another};
}

Iterable<dynamic> test3(dynamic x, dynamic another) {
  return {for (var [int _] in x) ...another};
}

main() {
  expectSetEquals(
    test1([0, 2], {1, 2, 3}) as Set,
    {1, 2, 3},
  );
  expectSetEquals(
    test2([0, 0], {1, 2, 3}) as Set,
    {},
  );
  expectThrows(() => test1([], {}));

  expectSetEquals(
    test2("foo", {1, 2, 3}) as Set,
    {1, 2, 3},
  );
  expectSetEquals(
    test2(false, {1, 2, 3}) as Set,
    {},
  );

  expectSetEquals(
    test3([[0], [1]], {1, 2, 3}) as Set,
    {1, 2, 3},
  );
  expectThrows(() => test3([null], {}));
}

expectSetEquals(Set x, Set y) {
  if (!x.containsAll(y) || !y.containsAll(x)) {
    throw "Expected sets '${x}' and '${y}' to be equal.";
  }
}

expectThrows(void Function() f) {
  bool hasThrown = true;
  try {
    f();
    hasThrown = false;
  } catch (e) {}
  if (!hasThrown) {
    throw "Expected the function to throw.";
  }
}
