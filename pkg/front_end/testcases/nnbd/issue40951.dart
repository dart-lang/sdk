// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  num field1;
  num field2;

  A() {}
  A.foo() {}
  A.bar(this.field1) {}
  A.baz(this.field1, this.field2) {}
}

abstract class B {
  num field1;
  num field2;

  B() {}
  B.foo() {}
  B.bar(this.field1) {}
  B.baz(this.field1, this.field2) {}
}

class C {
  final num? field1;
  final num? field2;

  C() {}
  C.foo() {}
  C.bar(this.field1) {}
  C.baz(this.field1, this.field2) {}
}

abstract class D {
  final num? field1;
  final num? field2;

  D() {}
  D.foo() {}
  D.bar(this.field1) {}
  D.baz(this.field1, this.field2) {}
}

main() {}
