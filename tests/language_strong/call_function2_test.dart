// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

typedef Object Func(Object x);

class Bar {
  int x = 42;

  Object call(Object x) {
    return 'Bar $x';
  }
}

Object baz(Object x) => x;

var map = <String, Func>{'baz': baz, 'bar': new Bar()};

Object test(String str, Object arg) {
  return map[str].call(arg);
}

void main() {
  Expect.equals(42, test('baz', 42));
  Expect.equals('Bar 42', test('bar', 42));
}
