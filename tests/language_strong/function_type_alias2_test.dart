// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--enable_type_checks
//
// Dart test for function type alias with optional parameters.

import "package:expect/expect.dart";

typedef int f1<T>([int a, int b, T c]);
typedef int f2<T>([int a, int b, T d]);
typedef int f3<T>({int a, int b, T c});
typedef int f4<T>({int a, int b, T d});

class A<T> {
  int baz([int a, int b, T c]) {}
  int bar({int a, int b, T c}) {}
}

int baz([int a, int b, int c]) {}

int bar({int a, int b, int c}) {}

main() {
  Expect.isTrue(baz is f1);
  Expect.isFalse(baz is f3);
  Expect.isFalse(bar is f1);
  Expect.isTrue(bar is f3);
  Expect.isTrue(baz is f1);
  Expect.isTrue(baz is f1<int>);
  Expect.isTrue(bar is f3<int>);
  Expect.isFalse(baz is f1<double>);
  Expect.isFalse(bar is f3<double>);
  Expect.isTrue(baz is f2);
  Expect.isFalse(bar is f4);
  Expect.isTrue(baz is f2<int>);
  Expect.isFalse(bar is f2<int>);

  A<int> a = new A<int>();
  Expect.isTrue(a.baz is f1);
  Expect.isFalse(a.baz is f3);
  Expect.isFalse(a.bar is f1);
  Expect.isTrue(a.bar is f3);
  Expect.isTrue(a.baz is f1);
  Expect.isTrue(a.baz is f1<Object>);
  Expect.isTrue(a.bar is f3<Object>);
  Expect.isTrue(a.baz is f1<int>);
  Expect.isTrue(a.bar is f3<int>);
  Expect.isTrue(a.baz is f1<double>);
  Expect.isTrue(a.bar is f3<double>);
  Expect.isTrue(a.baz is f2);
  Expect.isFalse(a.bar is f4);
  Expect.isTrue(a.baz is f2<Object>);
  Expect.isFalse(a.bar is f2<Object>);
}
