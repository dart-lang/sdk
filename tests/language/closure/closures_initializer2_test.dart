// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A<T> {
  var t;
  A() : t = (() => T);
}

expect(result, expected) {
  if (result != expected) {
    throw 'Expected $expected, got $result';
  }
}

main() {
  for (var i = 0; i < int.parse("1"); i++) {
    expect(new A<int>().t() is Type, true);
  }
}
