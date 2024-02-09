// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

var log;

class C1 {
  final int id;

  C1.n1(this.id, [String s = "a"]) {
    log = s;
  }
}

extension type ET1(int id) {
  ET1.n1(this.id, [String s = "b"]) {
    log = s;
  }
}

main() {
  var x = C1.n1;
  x(0);
  expect("a", log);

  var y = ET1.n1;
  y(1);
  expect("b", log);
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}