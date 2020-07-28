// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C {
  bool operator ==(Object other) => true;
}

class D extends C {
  bool operator ==(Object? other) => super == other;

  bool method1(dynamic o) => super == o;

  bool method2(Null o) => super == o;
}

class E {
  bool operator ==() => true;
}

class F extends E {
  bool operator ==(Object? other) => super == other;
}

main() {
  expect(true, D() == D());
  expect(false, D().method1(null));
  expect(false, D().method2(null));
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}
