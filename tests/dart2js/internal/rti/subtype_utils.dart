// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_rti' as rti;
import "package:expect/expect.dart";

final universe = rti.testingCreateUniverse();

String reason(String s, String t) => "$s <: $t";

void strictSubtype(String s, String t) {
  var sRti = rti.testingUniverseEval(universe, s);
  var tRti = rti.testingUniverseEval(universe, t);
  Expect.isTrue(rti.testingIsSubtype(universe, sRti, tRti), reason(s, t));
  Expect.isFalse(rti.testingIsSubtype(universe, tRti, sRti), reason(t, s));
}

void unrelated(String s, String t) {
  var sRti = rti.testingUniverseEval(universe, s);
  var tRti = rti.testingUniverseEval(universe, t);
  Expect.isFalse(rti.testingIsSubtype(universe, sRti, tRti), reason(s, t));
  Expect.isFalse(rti.testingIsSubtype(universe, tRti, sRti), reason(t, s));
}

void equivalent(String s, String t) {
  var sRti = rti.testingUniverseEval(universe, s);
  var tRti = rti.testingUniverseEval(universe, t);
  Expect.isTrue(rti.testingIsSubtype(universe, sRti, tRti), reason(s, t));
  Expect.isTrue(rti.testingIsSubtype(universe, tRti, sRti), reason(t, s));
}
