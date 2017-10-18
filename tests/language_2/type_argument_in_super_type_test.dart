// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class C {}

class A<T> {
  var field;
  A(this.field);
  T foo() => field;
  int bar() => field;
}

class B extends A<C> {
  B() : super(new C());
}

main() {
  B b = new B();
  Expect.equals(b.field, b.foo());
  Expect.throwsTypeError(b.bar);
}
