// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test verifies that annotations on parameters are correctly handled
// in the tree shaker.
// Regression test for https://github.com/dart-lang/sdk/issues/34644.

class ClassUsedInAnnotation1 {
  const ClassUsedInAnnotation1();
}

class ClassUsedInAnnotation2 {
  const ClassUsedInAnnotation2();
}

abstract class B {
  void foo(@ClassUsedInAnnotation1() String param);
}

class C implements B {
  void foo(String param) {}
}

typedef void Foo(@ClassUsedInAnnotation2() String param);

B x = new C();

void main() {
  x.foo("hi");

  Foo y = x.foo;
  y("hello");
}
