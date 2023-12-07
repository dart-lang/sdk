// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class Foo {
  int get a;
  num get b;
  num get c;
}

method1(o) {
  if (o case Foo(:var a, :int b)) {
    print(a + b);
  }
}

method2(o) {
  if (o case Foo(:var a, :var b, :int c)) {
    print(a + b + c);
  }
}

method3(o) {
  if (o case Foo(:var a, b: int(:var isEven), :int c)) {
    print(a + c);
    print(isEven);
  }
}
