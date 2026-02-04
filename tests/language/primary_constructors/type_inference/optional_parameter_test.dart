// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// We can omit the type of an optional parameter with a default value, in which
// case the type is inferred from the default value.

// SharedOptions=--enable-experiment=primary-constructors

import 'package:expect/expect.dart';
import "package:expect/static_type_helper.dart";

// Named parameters.
class Named({final x = 1, var y = 2}) {
  final Object o;

  this : o = (x, y).expectStaticType<Exactly<(int, int)>>() {
    (x, y).expectStaticType<Exactly<(int, int)>>();
  }
}

enum NamedEnum({final x = 1}) {
  e(x: 2), f();

  final Object o;

  this : o = x;

  void expectIntStaticType() {
    x.expectStaticType<Exactly<int>>();
  }
}

// Optional parameters.
class Optional([final x = 1, var y = 2]) {
  final Object o;

  this : o = (x, y).expectStaticType<Exactly<(int, int)>>() {
    (x, y).expectStaticType<Exactly<(int, int)>>();
  }
}

enum OptionalEnum([final x = 1]) {
  e(2), f();

  final Object o;

  this : o = x;

  void expectIntStaticType() {
    x.expectStaticType<Exactly<int>>();
  }
}

void main() {
  var named = Named();
  named.x.expectStaticType<Exactly<int>>();
  named.y.expectStaticType<Exactly<int>>();
  Expect.equals(1, named.x);
  Expect.equals(2, named.y);

  var namedEnumE = NamedEnum.e;
  namedEnumE.x.expectStaticType<Exactly<int>>();
  Expect.equals(2, namedEnumE.x);
  namedEnumE.expectIntStaticType();

  var namedEnumF = NamedEnum.f;
  namedEnumF.x.expectStaticType<Exactly<int>>();
  Expect.equals(1, namedEnumF.x);
  namedEnumF.expectIntStaticType();

  var optional = Optional();
  optional.x.expectStaticType<Exactly<int>>();
  optional.y.expectStaticType<Exactly<int>>();
  Expect.equals(1, optional.x);
  Expect.equals(2, optional.y);

  var optionalEnumE = OptionalEnum.e;
  optionalEnumE.x.expectStaticType<Exactly<int>>();
  Expect.equals(2, optionalEnumE.x);
  optionalEnumE.expectIntStaticType();

  var optionalEnumF = OptionalEnum.f;
  optionalEnumF.x.expectStaticType<Exactly<int>>();
  Expect.equals(1, optionalEnumF.x);
  optionalEnumF.expectIntStaticType();
}
