// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class S {}

class M1<X> {
  m1() => X;
}

class M2<Y> {
  m2() => Y;
}

class A<T> extends S with M1<T>, M2<T> {}

main() {
  var a = new A<int>();
  // Getting "int" when calling toString() on the int type is not required.
  // However, we want to keep the original names for the most common core types
  // so we make sure to handle these specifically in the compiler.
  Expect.equals("int", a.m1().toString());
  Expect.equals("int", a.m2().toString());
  a = new A<String>();
  Expect.equals("String", a.m1().toString());
  Expect.equals("String", a.m2().toString());
}
