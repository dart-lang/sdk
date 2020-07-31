// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A<T> {
  foo(T x) {
    print('T = $T');
    print('x.runtimeType = ${x.runtimeType}');
    print('x is T = ${x is T}');
  }
}

typedef IntFunc = void Function(int);
typedef StringFunc = void Function(String);

void main() {
  void inner<S>(S y) {}

  IntFunc innerOfInt = inner;
  A a = new A<IntFunc>();
  a.foo(innerOfInt);

  StringFunc innerOfString = inner;
  Expect.throwsTypeError(() {
    a.foo(innerOfString);
  });
}
