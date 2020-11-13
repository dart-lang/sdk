// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

// VMOptions=--enable-isolate-groups
// VMOptions=--no-enable-isolate-groups

library test_extension_test;

import 'dart:isolate';

import "test_extension.dart";

class Expect {
  static void equals(expected, actual, [msg]) {
    if (expected != actual) {
      if (msg == null) msg = "Expected: $expected. Actual: $actual";
      throw new StateError(msg);
    }
  }

  static void isNull(x, [msg]) {
    if (x != null) {
      if (msg != null) msg = "$x not null";
      throw new StateError(msg);
    }
  }
}

isolateHandler(_) {}

main() async {
  Expect.equals('cat 13', new Cat(13).toString(), 'new Cat(13).toString()');

  Expect.equals(3, Cat.ifNull(null, 3), 'Cat.ifNull(null, 3)');
  Expect.equals(4, Cat.ifNull(4, null), 'Cat.ifNull(4, null)');
  Expect.equals(5, Cat.ifNull(5, 9), 'Cat.ifNull(5, 9)');
  Expect.isNull(Cat.ifNull(null, null), 'Cat.ifNull(null, null)');

  try {
    Cat.throwMeTheBall("ball");
  } on String catch (e) {
    Expect.equals("ball", e);
  }

  await Isolate.spawn(isolateHandler, []);
}
