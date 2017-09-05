// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'lib/sources.dart';

class C1 extends A1 {}

class C2 implements A2 {}

class C3 extends Object with A3 {}

typedef A4 F1(A5 a, [A6 b]);
typedef A4 F2(A5 a, {A7 b});

A8 topLevelVariable1;
var topLevelVariable2 = A9;

A10 topLevelFunction1(A11 a, [A12 b]) => null;
A10 topLevelFunction2(A11 a, {A13 b}) => null;

@Meta(A14)
class X {}

class Meta {
  final f;
  const Meta(this.f);
}
