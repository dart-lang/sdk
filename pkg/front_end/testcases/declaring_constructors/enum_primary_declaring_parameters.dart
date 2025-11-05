// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

enum const E1(int a) { x(0) }

enum const E2(var int i) { x(0) } // Error

enum const E3(final int i) { x(0) }

enum const E4({final int? a, required final int b, final int c = 42}) {
  x(b: 1),
  y(a: 0, b: 1),
  z(b: 1, c: 2),
}

enum const E5(final int a, [final int? b, final int c = 42]) {
  x(0),
  y(0, 1),
  z(0, 1, 2),
}


enum const E6(int a, [int? b, int c = 42]) {
  x(0),
  y(0, 1),
  z(0, 1, 2),
}


enum const E7({int? a, required int b, int c = 42]) {
  x(b: 1),
  y(a: 0, b: 1),
  z(b: 1, c: 2),
}
