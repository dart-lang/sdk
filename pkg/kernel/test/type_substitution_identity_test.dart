// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:kernel/kernel.dart';
import 'package:kernel/type_algebra.dart';
import 'type_parser.dart';
import 'type_unification_test.dart' show testCases;
import 'package:test/test.dart';

checkType(DartType type) {
  var map = {new TypeParameter(): const DynamicType()};
  var other = substitute(type, map);
  if (!identical(type, other)) {
    fail('Identity substitution test failed for $type');
  }
  other = Substitution.fromUpperAndLowerBounds(map, map).substituteType(type);
  if (!identical(type, other)) {
    fail('Identity bounded substitution test failed for $type');
  }
}

main() {
  for (var testCase in testCases) {
    test('$testCase', () {
      var env = new LazyTypeEnvironment();
      checkType(env.parse(testCase.type1));
      checkType(env.parse(testCase.type2));
    });
  }
}
