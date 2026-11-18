// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'multi_module_helper1.dart';

int isOdd(int n) => n == 0 ? 0 : isEven(n - 1);

int callHelper1Add(int x) =>
    helper1Add(x) + helper1Add(x, 20) + helper1Add(x, 20, 300);

int helper2Named({int a = 1, required int b}) => 10 * a + b;

class B1 extends A1 {
  @override
  int overridden() => 20;

  int b1Method() => a1Method() + 2;

  int _private() => 200;
  int callB1Private() => _private();
}

class B2 extends A2 {
  @override
  int overridden() => 40;

  int b2Method() => a2Method() + 4;
}

B2 createB2() => B2();
int callA2FromHelper2(A2 a2) => a2.a2Method() + a2.callOverridden();
