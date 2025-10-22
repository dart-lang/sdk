// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// A basic declaring header constructor.

// SharedOptions=--enable-experiment=declaring-constructors

import 'package:expect/expect.dart';

class Point(var int x, var int y);

class PointFinal(final int x, final int y);

// Constant constructors.
class const CConst(final int x);

extension type const ExtConst(final int x);

enum const EnumConst(final int x) {
  e(1);
}

// Initializing parameters.
class CInitParameters(final int x, this.y) {
  late int y;
}

// Super parameters.
class C1(final int y);
class CSuperParameters(final int x, super.y) extends C1;

// Named parameters (regular and required).
class CNamedParameters({final int x = 1, required var int y});

enum EnumNamedParameters({final int x = 1, required var int y}) {
  e(x: 1, y: 2);
}

// Optional parameters.
class COptionalParameters([final int x = 1, var int y = 2]);

enum EnumOptionalParameters([final int x = 1, var int y = 2]) {
  e(1, 2);
}

// TODO(kallentu): Add tests for the type being inferred from the default value.

void main() {
  var p1 = Point(1, 2);
  Expect.equals(1, p1.x);
  Expect.equals(2, p1.y);

  p1.x = 3;
  Expect.equals(3, p1.x);

  var p2 = PointFinal(3, 4);
  Expect.equals(3, p2.x);
  Expect.equals(4, p2.y);

  Expect.equals(1, const CConst(1).x);

  Expect.equals(1, const ExtConst(1).x);

  Expect.equals(1, const EnumConst.e.x);

  Expect.equals(1, CInitParameters(1, 2).x);
  Expect.equals(2, CInitParameters(1, 2).y);

  Expect.equals(1, CSuperParameters(1, 2).x);
  Expect.equals(2, CSuperParameters(1, 2).y);

  Expect.equals(1, CNamedParameters(y: 2).x);
  Expect.equals(2, CNamedParameters(y: 2).y);

  Expect.equals(1, const EnumNamedParameters.e.x);
  Expect.equals(2, const EnumNamedParameters.e.y);

  Expect.equals(1, COptionalParameters().x);
  Expect.equals(2, COptionalParameters().y);

  Expect.equals(1, const EnumOptionalParameters.e.x);
  Expect.equals(2, const EnumOptionalParameters.e.y);
}
