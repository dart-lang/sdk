// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that generic methods can be specialized after being torn off, and that
// their specialized versions are correctly constructed.

library generic_methods_tearoff_specialization_test;

import "test_base.dart";

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

  expectTrue(f is Int2Int);
  expectTrue(f is! String2String);
  expectTrue(f is! Object2Object);
  expectTrue(f is! GenericMethod);

  expectTrue(g is! Int2Int);
  expectTrue(g is String2String);
  expectTrue(g is! Object2Object);
  expectTrue(g is! GenericMethod);

  expectTrue(h is! Int2Int);
  expectTrue(h is! String2String);
  expectTrue(h is Object2Object);
  expectTrue(g is! GenericMethod);

  expectTrue(generic is! Int2Int);
  expectTrue(generic is! String2String);
  expectTrue(generic is! Object2Object);
  expectTrue(generic is GenericMethod);
}
