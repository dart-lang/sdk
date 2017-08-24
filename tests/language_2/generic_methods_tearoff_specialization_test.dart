// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that generic methods can be specialized after being torn off, and that
// their specialized versions are correctly constructed.

library generic_methods_tearoff_specialization_test;

import "package:expect/expect.dart";

class A {
  T fun<T>(T t) => t;
}

typedef Int2Int = int Function(int);
typedef String2String = String Function(String);
typedef Object2Object = Object Function(Object);
typedef GenericMethod = T Function<T>(T);

main() {
  A a = new A();
  Int2Int f = a.fun;
  String2String g = a.fun;
  Object2Object h = a.fun;
  var generic = a.fun;

  Expect.isTrue(f is Int2Int);
  Expect.isTrue(f is! String2String);
  Expect.isTrue(f is! Object2Object);
  Expect.isTrue(f is! GenericMethod);

  Expect.isTrue(g is! Int2Int);
  Expect.isTrue(g is String2String);
  Expect.isTrue(g is! Object2Object);
  Expect.isTrue(g is! GenericMethod);

  Expect.isTrue(h is! Int2Int);
  Expect.isTrue(h is! String2String);
  Expect.isTrue(h is Object2Object);
  Expect.isTrue(g is! GenericMethod);

  Expect.isTrue(generic is! Int2Int);
  Expect.isTrue(generic is! String2String);
  Expect.isTrue(generic is! Object2Object);
  Expect.isTrue(generic is GenericMethod);
}
