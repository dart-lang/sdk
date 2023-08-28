// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that field promotion takes effect when the thing being promoted is a
// scrutinee of a switch statement.

// SharedOptions=--enable-experiment=inference-update-2

import '../static_type_helper.dart';

class C {
  final Object? _o;
  C(this._o);
}

T second<T>(dynamic x, T y) => y;

void castPattern(C c, C c2, bool b) {
  switch (c._o) {
    case _ as num when b:
      c._o.expectStaticType<Exactly<num>>();
    case _ when second(c = c2, b):
      break;
    case _ as int:
      c._o.expectStaticType<Exactly<Object?>>();
  }
}

void listPattern(C c, C c2, bool b) {
  switch (c._o) {
    case [] when b:
      c._o.expectStaticType<Exactly<List<Object?>>>();
    case _ when second(c = c2, b):
      break;
    case []:
      c._o.expectStaticType<Exactly<Object?>>();
  }
}

void mapPattern(C c, C c2, bool b) {
  switch (c._o) {
    case {0: _} when b:
      c._o.expectStaticType<Exactly<Map<Object?, Object?>>>();
    case _ when second(c = c2, b):
      break;
    case {0: _}:
      c._o.expectStaticType<Exactly<Object?>>();
  }
}

void nullAssertPattern(C c, C c2, bool b) {
  switch (c._o) {
    case (_!, _) when b:
      c._o.expectStaticType<Exactly<(Object, Object?)>>();
    case _ when second(c = c2, b):
      break;
    case (_, _!):
      c._o.expectStaticType<Exactly<Object?>>();
  }
}

void nullCheckPattern(C c, C c2, bool b) {
  switch (c._o) {
    case _? when b:
      c._o.expectStaticType<Exactly<Object>>();
    case _ when second(c = c2, b):
      break;
    case _?:
      c._o.expectStaticType<Exactly<Object?>>();
  }
}

void objectPattern(C c, C c2, bool b) {
  switch (c._o) {
    case int() when b:
      c._o.expectStaticType<Exactly<int>>();
    case _ when second(c = c2, b):
      break;
    case int():
      c._o.expectStaticType<Exactly<Object?>>();
  }
}

void recordPattern(C c, C c2, bool b) {
  switch (c._o) {
    case () when b:
      c._o.expectStaticType<Exactly<()>>();
    case _ when second(c = c2, b):
      break;
    case ():
      c._o.expectStaticType<Exactly<Object?>>();
  }
}

void variablePattern(C c, C c2, bool b) {
  switch (c._o) {
    case int x when b:
      c._o.expectStaticType<Exactly<int>>();
    case _ when second(c = c2, b):
      break;
    case int x:
      c._o.expectStaticType<Exactly<Object?>>();
  }
}

void wildcardPattern(C c, C c2, bool b) {
  switch (c._o) {
    case int _ when b:
      c._o.expectStaticType<Exactly<int>>();
    case _ when second(c = c2, b):
      break;
    case int _:
      c._o.expectStaticType<Exactly<Object?>>();
  }
}

main() {
  castPattern(C(0), C(0), false);
  listPattern(C([]), C([]), false);
  mapPattern(C({}), C({}), false);
  nullAssertPattern(C(0), C(0), false);
  nullCheckPattern(C(0), C(0), false);
  objectPattern(C(0), C(0), false);
  recordPattern(C(()), C(()), false);
  variablePattern(C(0), C(0), false);
  wildcardPattern(C(0), C(0), false);
}
