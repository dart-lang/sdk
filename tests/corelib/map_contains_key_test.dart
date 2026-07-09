// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  const A();
}

class B extends A {
  const B();
}

main() {
  var map1 = new Map<B, B>();
  map1[const B()] = const B();
  var map2 = new Map<B, B>();
  var list = <B>[const B()];

  var maps = [map1, map2];
  for (var map in maps) {
    // Test that the map accepts a key is not of the same type:
    //   Map<B, ?>.containsValue(A)
    Expect.isFalse(map.containsKey(new A()));
  }
}
