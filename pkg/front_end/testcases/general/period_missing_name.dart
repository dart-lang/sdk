// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

void f(int a) {
  a.();
  a.(0);
  a.(0, b: 1);
  a.toString().(0).isEmpty;
  a..toString().(0);
  a.[0];
  a.<int>[];
  a.{};
  a."s";
}

void g(int? a) {
  a?.(0);
}

void h() {
  math.(0);
  math.[0];
}

main() {}
