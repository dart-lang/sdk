// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C1(a, var b, final c) {
  int d = a; // Error
  int e = b; // Error
  int f = c; // Error
}

class C2([a = null, var b = null, final c = null]) {
  int d = a; // Error
  int e = b; // Error
  int f = c; // Error
}

class C3({a = null, var b = null, final c = null}) {
  int d = a; // Error
  int e = b; // Error
  int f = c; // Error
}

extension type ET1(a);

extension type ET2([a = null]);

extension type ET3({a = null});

test(C1 c1, C2 c2, C3 c3, ET1 e1, ET2 e2, ET3 e3) {
  int a = c1.b; // Error
  int b = c1.c; // Error
  int c = c2.b; // Error
  int d = c2.c; // Error
  int e = c3.b; // Error
  int f = c3.c; // Error
  int g = e1.a; // Error
  int h = e2.a; // Error
  int i = e3.a; // Error
}
