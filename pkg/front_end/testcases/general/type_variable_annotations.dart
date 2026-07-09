// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  const A();
}

void method<@A() T>() {}

typedef F<@A() T> = void Function(T);

class Class<@A() T> {
  void method<@A() T>() {
    void local<@A() T>() {}
  }
}

extension Extension<@A() T> on T {
  void method<@A() T>() {}
}

main() {}
