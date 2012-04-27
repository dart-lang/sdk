// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--enable_type_checks
//
// Dart test for function type alias with named optional parameters.

typedef int f1<T>([int a, int b, T c]);
typedef int f2<T>([int a, int b, T d]);

class A<T> {
  int baz([int a, int b, T c]) {
  }
}

int baz([int a, int b, int c]) {
}

main() {
  Expect.isTrue(baz is f1);
  Expect.isTrue(baz is f1<int>);
  Expect.isFalse(baz is f1<double>);
  Expect.isFalse(baz is f2);
  Expect.isFalse(baz is f2<int>);

  A<int> a = new A<int>();
  Expect.isTrue(a.baz is f1);
  Expect.isTrue(a.baz is f1<int>);
  Expect.isFalse(a.baz is f1<double>);
  Expect.isFalse(a.baz is f2);
  Expect.isFalse(a.baz is f2<int>);
}
