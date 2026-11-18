// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'multi_module_helper1.dart';
import 'multi_module_helper2.dart';

void expectEquals(int expected, int actual) {
  if (expected != actual) {
    print('expectEquals failed');
    _trap();
  }
}

void _trap() => _trap();

void main() {
  // Mutual recursion across modules.
  expectEquals(1, isEven(6));
  expectEquals(0, isEven(7));
  expectEquals(0, isOdd(6));
  expectEquals(1, isOdd(7));

  // Optional positional and named parameters across modules.
  expectEquals(
    (1 + 10 + 100) + (1 + 20 + 100) + (1 + 20 + 300),
    callHelper1Add(1),
  );
  expectEquals((10 * 1 + 3) + (10 * 5 + 3), callHelper2Named(3));

  // Cross-module class inheritance hierarchy: A1 -> B1 -> A2 -> B2.
  final a1 = A1();
  final b1 = B1();
  final a2 = createA2();
  final b2 = createB2();

  expectEquals(10, a1.callOverridden());
  expectEquals(20, b1.callOverridden());
  expectEquals(30, a2.callOverridden());
  expectEquals(40, b2.callOverridden());

  expectEquals(1, a1.a1Method());
  expectEquals(1 + 2, b1.b1Method());
  expectEquals(1 + (1 + 2) + 3, a2.a2Method());
  expectEquals((1 + (1 + 2) + 3) + 4, b2.b2Method());

  // Cross-module instance calls on objects allocated in another module.
  expectEquals(7 + 30, callA2FromHelper2(a2));
  expectEquals(11 + 40, callB2FromHelper1(b2));

  // Library-private methods with the same name in different modules do not
  // collide.
  expectEquals(100, b2.callA1Private());
  expectEquals(200, b2.callB1Private());
}
