// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


enum E1 {
  e0(0), e1(1, 2);

  final x, y;

  new (int x, [int y = 0]) : x = x, y = y;
}

augment enum E1 {
  ;
  augment const E1(x, [y]);
}

enum E2 {
  e0(x: 1), e1(x: 1, y: 2);

  final x, y;
  new ({required int x, int y = 0}) : x = x, y = y;
}

augment enum E2 {
  ;
  augment const E2({required x, y});
}

main() {

}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}