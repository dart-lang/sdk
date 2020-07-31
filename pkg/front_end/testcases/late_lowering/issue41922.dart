// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

bool _called = false;

String init(String val) {
  if (!_called) {
    _called = true;
    throw new Exception();
  }
  return val;
}

class C {
  static late String? s = init("lateValue");
}

main() {
  throws(() {
    C.s;
  });
  expect("lateValue", C.s);
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
  throw 'Expected exception';
}
