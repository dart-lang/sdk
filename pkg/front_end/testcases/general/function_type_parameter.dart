// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.13

class A {
  const A();
}

void Function<@A() T>(T)? f;

typedef F = void Function<@A() T>(T);

typedef void G<@A() T>(T t);

void method1<@A() T>(T t) {}

void method2(void Function<@A() T>(T) f) {}

class Class<T extends void Function<@A() S>(S)> {}

main() {
  void local<@A() T>(T t) {}

  void Function<@A() T>(T)? f;
}
