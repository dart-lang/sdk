// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

test(List<int> list) {
  var (<num>[v] as List<int>) = list;
  expect(42, v);
}

test2() {
  num? x = 2 > 1 ? 42 : null;
  var (v2!) = x;
  expect(42, v2);
}

main() {
  test(<int>[42]);
  throws(() => test(<int>[]));
  throws(() => test(<int>[1, 2]));

  test2();
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}

throws(void Function() f) {
  try {
    f();
  } catch (_) {
    return;
  }
  throw 'Missing exception';
}
