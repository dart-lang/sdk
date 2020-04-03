// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that a torn off method of a generic class is not a generic method,
// and that it is correctly specialized.

library generic_methods_generic_class_tearoff_test;

import "package:expect/expect.dart";

class A<T> {
  T fun(T t) => t;
}

typedef Int2Int = int Function(int);
typedef String2String = String Function(String);
typedef Object2Object = Object Function(Object);
typedef GenericMethod = T Function<T>(T);

main() {
  A<int> x = new A<int>();
  var f = x.fun; // The type of f should be 'int Function(Object)'.
  A<String> y = new A<String>();
  var g = y.fun; // The type of g should be 'String Function(Object)'.
  A z = new A();
  var h = z.fun; // The type of h should be 'dynamic Function(Object)'.

  Expect.isTrue(f is Int2Int);
  Expect.isTrue(f is! String2String);
  Expect.isTrue(f is Object2Object);
  Expect.isTrue(f is! GenericMethod);

  Expect.isTrue(g is! Int2Int);
  Expect.isTrue(g is String2String);
  Expect.isTrue(g is Object2Object);
  Expect.isTrue(g is! GenericMethod);

  Expect.isTrue(h is! Int2Int);
  Expect.isTrue(h is! String2String);
  Expect.isTrue(h is Object2Object);
  Expect.isTrue(h is! GenericMethod);
}
