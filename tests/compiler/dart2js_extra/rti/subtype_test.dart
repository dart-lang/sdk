// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_rti' as rti;
import "package:expect/expect.dart";

main() {
  testCodeUnits();
}

void testCodeUnits() {
  var universe = rti.testingCreateUniverse();

  var intRule = rti.testingCreateRule();
  rti.testingAddSupertype(intRule, 'num', []);

  var listRule = rti.testingCreateRule();
  rti.testingAddSupertype(listRule, 'Iterable', ['1']);

  var codeUnitsRule = rti.testingCreateRule();
  rti.testingAddSupertype(codeUnitsRule, 'List', ['int']);

  rti.testingAddRule(universe, 'int', intRule);
  rti.testingAddRule(universe, 'List', listRule);
  rti.testingAddRule(universe, 'CodeUnits', codeUnitsRule);

  var rti1 = rti.testingUniverseEval(universe, 'List<CodeUnits>');
  var rti2 = rti.testingUniverseEval(universe, 'Iterable<List<int>>');

  Expect.isTrue(rti.testingIsSubtype(universe, rti1, rti2));
  Expect.isFalse(rti.testingIsSubtype(universe, rti2, rti1));
}
