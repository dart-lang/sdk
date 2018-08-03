// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Test to make sure the do/while loop exit condition is generated.

var global;

class A {
  var array;

  initArray() {
    if (global[0] == null) {
      return [2];
    } else {
      var map = new Map();
      map[0] = 2;
      return map;
    }
  }

  bar() {
    array = initArray();
    var element;
    do {
      element = array[0]; // bailout here
      if (element is Map) continue;
      if (element == null) break;
    } while (element != 2);
    return global[0]; // bailout here
  }
}

void main() {
  global = [2];
  for (int i = 0; i < 2; i++) {
    Expect.equals(2, new A().bar());
  }

  global = new Map();
  global[0] = 2;
  for (int i = 0; i < 2; i++) {
    Expect.equals(2, new A().bar());
  }
}
