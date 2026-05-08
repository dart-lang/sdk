// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C0 {
  int b;
  final int c;
  int d;
  int e;
  int f;
  int g = 42;

  C0(int a, this.b, this.c) : d = a, e = b, f = c;
}

class C1(int a, var int b, final int c) {
  int d = a;
  int e = b;
  int f = c;
  int g = 42;
}
