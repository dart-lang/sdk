// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void foo1(x, [a = 'default_a', b = 'default_b']) {
  print('x = $x');
  print('a = $a');
  print('b = $b');
}

void foo2(y, z, {c = 'default_c', a = 42, b = const ['default_b']}) {
  print('y = $y');
  print('z = $z');
  print('a = $a');
  print('b = $b');
  print('c = $c');
}

void foo3<P, Q>(z, y, {bool a: false, Map<P, Q> b}) {
  print(P);
  print(y);
  print(b);
}

main() {
  foo1('fixed_x', 'concrete_a');
  foo2('fixed_y', 'fixed_z', a: 'concrete_a');
}
