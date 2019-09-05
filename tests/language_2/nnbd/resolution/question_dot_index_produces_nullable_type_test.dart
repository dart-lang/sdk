// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=non-nullable

void main() {}

void f1(NotGeneric x) {
  x[0] + 1; //# 01: ok
}

void f2(NotGeneric? x) {
  x?.[0] + 1; //# 02: compile-time error
}

void f3<T extends num>(Generic<T>? x) {
  x?.[0] + 1; //# 03: compile-time error
}

void f4<T extends num>(Generic<T?> x) {
  x[0] + 1; //# 04: compile-time error
}

class NotGeneric {
  int operator[](int index) => throw 'unreachable';
  void operator[]=(int index, int value) => throw 'unreachable';
}

class Generic<T> {
  T operator[](int index) => throw 'unreachable';
  void operator[]=(int index, T value) => throw 'unreachable';
}
