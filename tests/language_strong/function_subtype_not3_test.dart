// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for constructors and initializers.

// Check negative function subtyping tests.

import 'package:expect/expect.dart';

typedef void Foo<T>(T t);
typedef void Bar(int i);

class Class<T> {
  test(bool expectedResult, var o, String typeName) {
    void local() {
      Expect.equals(expectedResult, o is! Foo<T>, "bar is! Foo<$typeName>");
      Expect.isFalse(o is! Bar, "bar is! Bar");
    }

    local();
  }
}

void bar(int i) {}

void main() {
  new Class().test(false, bar, "dynamic");
  new Class<int>().test(false, bar, "int");
  new Class<bool>().test(true, bar, "bool");
}
