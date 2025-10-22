// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// A basic declaring body constructor.

// SharedOptions=--enable-experiment=declaring-constructors

import 'package:expect/expect.dart';

class Point {
  this(var int x, var int y);
}

class PointFinal {
  this(final int x, final int y);
}

// Constant constructors.
class CConst {
  const this(final int x);
}

extension type ExtConst {
  const this(final int x);
}

enum EnumConst {
  e(1);

  const this(final int x);
}

// Initializing parameters.
class CInitParameters {
  late int y;
  this(this.y);
}

// Super parameters.
class C1(final int y);
class CSuperParameters extends C1{
  this(final int x, super.y);
}

// Named parameters (regular and required).
class CNamedParameters {
  this({final int x = 1, required var int y});
}

enum EnumNamedParameters {
  e(x: 2, y: 3), f(y: 3);

  const this({final int x = 1, required var int y});
}

// Optional parameters.
class COptionalParameters {
  this([final int x = 1, var int y = 2]);
}

enum EnumOptionalParameters {
  e(3, 4), f(3), g();

  const this([final int x = 1, var int y = 2]);
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

  Expect.equals(1, CInitParameters(1).y);

  Expect.equals(1, CSuperParameters(1, 2).x);
  Expect.equals(2, CSuperParameters(1, 2).y);

  Expect.equals(1, CNamedParameters(y: 2).x);
  Expect.equals(2, CNamedParameters(y: 2).y);

  Expect.equals(2, const EnumNamedParameters.e.x);
  Expect.equals(3, const EnumNamedParameters.e.y);
  Expect.equals(1, const EnumNamedParameters.f.x);
  Expect.equals(3, const EnumNamedParameters.f.y);

  Expect.equals(1, COptionalParameters().x);
  Expect.equals(2, COptionalParameters().y);

  Expect.equals(3, const EnumOptionalParameters.e.x);
  Expect.equals(4, const EnumOptionalParameters.e.y);
  Expect.equals(3, const EnumOptionalParameters.f.x);
  Expect.equals(2, const EnumOptionalParameters.f.y);
  Expect.equals(1, const EnumOptionalParameters.g.x);
  Expect.equals(2, const EnumOptionalParameters.g.y);
}
