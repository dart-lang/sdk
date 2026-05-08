// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C1(var int a, final String b, double c);

class C2([var int a = 0, final String b = '', double c = 0.0]);

class C3({required var int a, required final String b, required double c});

class C4({var int a = 0, final String b = '', double c = 0.0});

test(C1 c1) {
  c1.b = '5'; // Error
  c1.c; // Error
  c1.c = 6.0; // Error
}

main() {
  var c1 = C1(1, '2', 3.0);
  print(c1.a);
  print(c1.b);
  c1.a = 4;
  print(c1.b);
}