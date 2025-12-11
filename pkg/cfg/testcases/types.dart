// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A<T> {
  void bar() {
    foo<int>(1);
    foo<Map<String, T>>(2);
  }

  void foo<U>(Object o) {
    if (o is List<T>) {
      o as Map;
    }
  }

  factory A() => A<T>._();
  A._();
}

void main() {}
