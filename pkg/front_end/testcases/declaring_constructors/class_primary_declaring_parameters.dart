// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C1(int a, [int? b]) {}

class C2(var int a, [var int? b]) {}

class C3(final int a, [final int? b]) {}

class const C4(int a) {}

class const C5(var int a) {} // Error

class const C6(final int b) {}

class C7({int? a, required int b}) {}

class C8({var int? a, required var int b}) {}

class C9({final int? a, required final int b}) {}


main() {
  new C1(0);
  new C1(0, 1);
  new C2(0);
  new C2(0, 1);
  new C3(0);
  new C3(0, 1);
  new C4(0);
  const C4(0);
  new C5(0);
  new C6(0);
  const C6(0);
  new C7(b: 1);
  new C7(a: 0, b: 1);
  new C8(b: 1);
  new C8(a: 0, b: 1);
  new C9(b: 1);
  new C9(a: 0, b: 1);
}