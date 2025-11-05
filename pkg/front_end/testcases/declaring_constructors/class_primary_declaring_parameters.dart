// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C1(int a, [int? b, int c = 42]) {}

class C2(var int a, [var int? b, var int c = 42]) {}

class C3(final int a, [final int? b, final int c = 42]) {}

class const C4(int a) {}

class const C5(var int a) {} // Error

class const C6(final int b) {}

class C7({int? a, required int b, int c = 42}) {}

class C8({var int? a, required var int b, var int c = 42}) {}

class C9({final int? a, required final int b, final int c = 42}) {}

class const C10(final int a, [final int? b, final int c = 42]) {}

class const C11({final int? a, required final int b, final int c = 42}) {}


main() {
  new C1(0);
  new C1(0, 1);
  new C1(0, 1, 2);
  new C2(0);
  new C2(0, 1);
  new C2(0, 1, 2);
  new C3(0);
  new C3(0, 1);
  new C3(0, 1, 2);
  new C4(0);
  const C4(0);
  new C5(0);
  new C6(0);
  const C6(0);
  new C7(b: 1);
  new C7(a: 0, b: 1);
  new C7(a: 0, b: 1, c: 2);
  new C8(b: 1);
  new C8(a: 0, b: 1);
  new C8(a: 0, b: 1, c: 2);
  new C9(b: 1);
  new C9(a: 0, b: 1);
  new C9(a: 0, b: 1, c: 2);
  new C10(0);
  new C10(0, 1);
  new C10(0, 1, 2);
  const C10(0);
  const C10(0, 1);
  const C10(0, 1, 2);
  new C11(b: 1);
  new C11(a: 0, b: 1);
  new C11(a: 0, b: 1, c: 2);
  const C11(b: 1);
  const C11(a: 0, b: 1);
  const C11(a: 0, b: 1, c: 2);
}