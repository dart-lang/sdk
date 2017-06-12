// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Test verifying that the type argument vector of subclasses are properly
// initialized by the class finalizer.

import "package:expect/expect.dart";

class A<T> {
  A();
}

class B extends A<Object> {
  B();
}

class C extends B {
  C();
}

main() {
  var a = new A<String>();
  var b = new B();
  var c = new C();
  Expect.isTrue(a is Object);
  Expect.isTrue(a is A<Object>);
  Expect.isTrue(a is A<String>);
  Expect.isTrue(a is! A<int>);
  Expect.isTrue(b is Object);
  Expect.isTrue(b is A<Object>);
  Expect.isTrue(b is! A<String>);
  Expect.isTrue(b is Object);
  Expect.isTrue(c is Object);
  Expect.isTrue(c is A<Object>);
  Expect.isTrue(c is! A<String>);
  Expect.isTrue(c is B);
}
