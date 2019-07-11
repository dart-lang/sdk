// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  final x = null;

  const A.named1() sync* {}

  const A.named2() : x = new Object();
}

external foo(String x) {
  return x.length;
}

class B {}

class C {
  B b;
}

abstract class AbstractClass {
  const AbstractClass.id();
}

m() {
  const AbstractClass.id();
  (new C()?.b ??= new B()).b;
}

main() {}
