// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'multi_module_helper2.dart';

int isEven(int n) => n == 0 ? 1 : isOdd(n - 1);

int helper1Add(int a, [int b = 10, int c = 100]) => a + b + c;

int callHelper2Named(int x) => helper2Named(b: x) + helper2Named(b: x, a: 5);

class A1 {
  int a1Method() => 1;
  int overridden() => 10;
  int callOverridden() => overridden();

  int _private() => 100;
  int callA1Private() => _private();
}

class A2 extends B1 {
  @override
  int overridden() => 30;

  int a2Method() => a1Method() + b1Method() + 3;
}

A2 createA2() => A2();
int callB2FromHelper1(B2 b2) => b2.b2Method() + b2.callOverridden();
