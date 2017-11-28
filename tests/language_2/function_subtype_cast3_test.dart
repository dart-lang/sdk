// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for constructors and initializers.

// Check function subtyping casts.

import 'package:expect/expect.dart';

typedef void Foo<T>(T t);
typedef void Bar(int i);

class Class<T> {
  test(bool expectedResult, var o, String typeName) {
    void local() {
      if (expectedResult) {
        Expect.isNotNull(o as Foo<T>, "bar as Foo<$typeName>");
      } else {
        Expect.throws(() => o as Foo<T>, (e) => true, "bar as Foo<$typeName>");
      }
      Expect.isNotNull(o as Bar, "bar as Bar");
    }

    local();
  }
}

void bar(int i) {}

void main() {
  new Class().test(true, bar, "dynamic");
  new Class<int>().test(true, bar, "int");
  new Class<bool>().test(false, bar, "bool");
}
