// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Test for dart2js to make sure the computed bailout environment is
// correct.

var global;

class A {
  var array;

  foo() {
    do {
      var element = global;
      if (element is Map) continue;
      if (element is num) break;
    } while (true);
    return array[0]; // bailout here.
  }
}

void main() {
  var a = new A();
  a.array = [42];
  global = 42;

  for (int i = 0; i < 2; i++) {
    Expect.equals(42, a.foo());
  }

  a.array = new Map();
  a.array[0] = 42;
  for (int i = 0; i < 2; i++) {
    Expect.equals(42, a.foo());
  }
  global = null;
}
