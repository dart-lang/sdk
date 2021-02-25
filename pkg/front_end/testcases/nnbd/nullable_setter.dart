// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C {
  String m = "";
  void set setter(String v) {}
  void operator []=(int index, String value) {}
}

extension on C? {
  void set setter(String v) {
    this?.m = v;
  }

  void operator []=(int index, String value) {
    this?.m = '$index$value';
  }
}

main() {
  C? c = new C() as C?;
  expect("", c?.m);
  c.setter = "42";
  expect("42", c?.m);
  c[42] = "87";
  expect("4287", c?.m);
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}
