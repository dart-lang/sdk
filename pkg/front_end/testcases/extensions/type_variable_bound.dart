// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.8

extension Extension<T> on T {
  T method1() => this;
}

extension BoundExtension<T extends Class> on T {
  T method2() => this;
}

class Class {}

class SubClass extends Class {}

Class test1<T>(T t1) {
  if (t1 is SubClass) {
    return t1.method1();
  }
  return new Class();
}

test2<T extends Class>(T t2) {
  if (T == SubClass) {
    SubClass subClass = t2.method2();
  }
}

test3<T>(T t3) {
  if (t3 is SubClass) {
    SubClass subClass = t3.method2();
  }
}

main() {}
