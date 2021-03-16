// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Requirements=nnbd

import 'dart:_rti' as rti;
import 'dart:_foreign_helper' show JS;
import "package:expect/expect.dart";

const typeRulesJson = r'''
{
  "B": {"A": []},
  "C": {"B": []}
}
''';
final typeRules = JS('=Object', 'JSON.parse(#)', typeRulesJson);

main() {
  var universe = rti.testingCreateUniverse();
  rti.testingAddRules(universe, typeRules);

  // Recipe is properly parsed
  var rti1 = rti.testingUniverseEval(universe, "@(B,{a!B,b:B,c!B})");

  // Subtype must be contravariant in its named parameter types
  var rti2 = rti.testingUniverseEval(universe, "@(B,{a!A,b:B,c!B})");
  Expect.isTrue(rti.testingIsSubtype(universe, rti2, rti1));
  rti2 = rti.testingUniverseEval(universe, "@(B,{a!B,b:A,c!B})");
  Expect.isTrue(rti.testingIsSubtype(universe, rti2, rti1));
  rti2 = rti.testingUniverseEval(universe, "@(B,{a!C,b:B,c!B})");
  Expect.isFalse(rti.testingIsSubtype(universe, rti2, rti1));
  rti2 = rti.testingUniverseEval(universe, "@(B,{a!B,b:C,c!B})");
  Expect.isFalse(rti.testingIsSubtype(universe, rti2, rti1));

  // Subtype may not omit optional named parameters
  rti2 = rti.testingUniverseEval(universe, "@(A,{a!A,c!A})");
  Expect.isFalse(rti.testingIsSubtype(universe, rti2, rti1));

  // Subtype may not omit required named parameters
  rti2 = rti.testingUniverseEval(universe, "@(A,{a!A,b:A})");
  Expect.isFalse(rti.testingIsSubtype(universe, rti2, rti1));

  // Subtype may contain additional named optional parameters
  rti2 = rti.testingUniverseEval(universe, "@(A,{a!A,b:A,c!A,d:A})");
  Expect.isTrue(rti.testingIsSubtype(universe, rti2, rti1));

  // Subtype may redeclare required parameters as optional.
  rti2 = rti.testingUniverseEval(universe, "@(A,{a:A,b:A,c:A})");
  Expect.isTrue(rti.testingIsSubtype(universe, rti2, rti1));

  // Subtype may not redeclare optional parameters as required
  rti2 = rti.testingUniverseEval(universe, "@(A,{a!A,b!A,c!A})");
  Expect.equals(
      hasUnsoundNullSafety, rti.testingIsSubtype(universe, rti2, rti1));

  // Subtype may not declare new required named parameters
  rti2 = rti.testingUniverseEval(universe, "@(A,{a!A,b:A,c!A,d!A})");
  Expect.equals(
      hasUnsoundNullSafety, rti.testingIsSubtype(universe, rti2, rti1));

  // Rti.toString() appears as expected
  Expect.equals('(B, {required B a, B b, required B c}) => dynamic',
      rti.testingRtiToString(rti1));

  // Rti debug string properly annotates all required parameters
  Expect.equals(
      2, 'required'.allMatches(rti.testingRtiToDebugString(rti1)).length);
}
