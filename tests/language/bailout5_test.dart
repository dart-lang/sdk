// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Test to make sure the bailout environment in dart2js is correct.

var global;

class A {
  var array;

  initArray() {
    return global[0] == null ? [null] : new Map();
  }

  bar() {
    array = initArray();
    do {
      var element = array[0]; // bailout here
      if (element is Map) continue;
      if (element == null) break;
    } while (true);
    return global[0]; // bailout here
  }

  baz() {
    do {
      var element = bar();
      if (element == null) return global[0]; // bailout here
      if (element is Map) continue;
      if (element is num) break;
    } while (true);
    return global[0]; // bailout here
  }
}

void main() {
  global = [1];
  for (int i = 0; i < 2; i++) {
    Expect.equals(1, new A().baz());
    Expect.equals(1, new A().bar());
  }
  global = new Map();
  for (int i = 0; i < 2; i++) {
    Expect.equals(null, new A().baz());
    Expect.equals(null, new A().bar());
  }

  global[0] = 42;
  for (int i = 0; i < 2; i++) {
    Expect.equals(42, new A().baz());
    Expect.equals(42, new A().bar());
  }
}
