// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

enum E1(final int x) {
  e0(0);
  this async;
}

enum E2(final int x) {
  e0(0);
  this: assert(x > 0) async;
}

enum E3(final int x) {
  e0(0);
  this async*;
}

enum E4(final int x) {
  e0(0);
  this: assert(x > 0) async*;
}

enum E5(final int x) {
  e0(0);
  this sync*;
}

enum E6(final int x) {
  e0(0);
  this: assert(x > 0) sync*;
}

mixin class M1() {
  this async;
}

mixin class M2() {
  this async*;
}


mixin class M3() {
  this sync*;
}
