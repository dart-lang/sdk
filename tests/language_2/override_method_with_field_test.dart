// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Test overriding a method with a field.

class Super {
  Super() : super();

  instanceMethod() => 42;
}

class Sub extends Super {
  Sub() : super();

  var instanceMethod = 87; // //# 01: compile-time error

  superInstanceMethod() => super.instanceMethod();
}

main() {
  var s = new Sub();
  Super sup = s;
  Sub sub = s;
  print(s.instanceMethod);
  Expect.equals(42, s.superInstanceMethod());
  Expect.equals(42, sup.superInstanceMethod()); //# 02: compile-time error
  Expect.equals(42, sub.superInstanceMethod());
}
