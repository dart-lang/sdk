// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class A {
  aMethod() {}
  abstractMethod();
  void set property1(_);
  void set property2(_);
  void set property3(_);
}

abstract class B extends A {
  final property1 = null;
  aMethod() {}
  bMethod() {}
}

class MyClass extends B {
  var property2;
  aaMethod() {}
  aMethod() {}
  bMethod() {}
  cMethod() {}
}

main() {}
