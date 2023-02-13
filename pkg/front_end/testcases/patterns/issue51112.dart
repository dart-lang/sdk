// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

test(dynamic x) {
  void Function() setToOne = () {};
  switch (x) {
    case [int y, _] when () { setToOne = () { y = 1; }; return true; }():
    case [_, int y] when () { setToOne = () { y = 1; }; return true; }():
      setToOne();
      return y;
    case [double y] when () { setToOne = () { y = 1.0; }; return true; }():
      setToOne();
      return y;
    default:
      return null;
  }
}

main() {
  expectEquals(test([0, "foo"]), 0);
  expectEquals(test(["foo", 0]), 0);
  expectEquals(test([3.14]), 1.0);
  expectEquals(test(null), null);
}

expectEquals(x, y) {
  if (x != y) {
    throw "Expected ${x} to be equal to ${y}.";
  }
}
