// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test overriding a method with a field.

class Super {
  Super() : super();

  instanceMethod() => 42;
}

class Sub extends Super {
  Sub() : super(), this.instanceMethod = 87;

  var instanceMethod; // Intentional static type error.

  superInstanceMethod() => super.instanceMethod();
}

main() {
  var s = new Sub();
  Super sup = s;
  Sub sub = s;
  Expect.equals(87, s.instanceMethod);
  Expect.equals(42, s.superInstanceMethod());
  Expect.equals(87, sup.instanceMethod);
  Expect.equals(42, sup.superInstanceMethod()); // Intentional static type error.
  Expect.equals(87, sub.instanceMethod);
  Expect.equals(42, sub.superInstanceMethod());
}
