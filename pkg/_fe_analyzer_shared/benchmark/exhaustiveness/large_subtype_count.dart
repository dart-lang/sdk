// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/exhaustiveness/exhaustive.dart';
import 'package:_fe_analyzer_shared/src/exhaustiveness/path.dart';
import 'package:_fe_analyzer_shared/src/exhaustiveness/profile.dart' as profile;
import 'package:_fe_analyzer_shared/src/exhaustiveness/static_type.dart';
import 'package:_fe_analyzer_shared/src/exhaustiveness/space.dart';

import '../../test/exhaustiveness/env.dart';
import '../../test/exhaustiveness/utils.dart';

/// These tests show some pitfalls of the exhaustiveness checking algorithm
/// where the witness candidate count is exponential in the size of the user
/// code.
void main() {
  profile.enabled = true;

  for (int i = 1; i <= 30; i++) {
    testSubtypeCount(i);
  }

  for (int i = 1; i <= 10; i++) {
    testFieldCount(i);
  }
}

/// Tests the how the number of subtypes affect the number of tested witness
/// candidates.
///
/// We create the sealed class A with n subtypes B1 to Bn:
///
///       (A)
///     /  |   \
///    B1 B2 ... Bn
///
/// with the trivial matching by a record type:
///
///     method(({A x, A y, A z, A w} r) => switch (r) {
///       (x: _, y: _, z: _, w: _) => 0,
///     };
///
/// which has the worst case `case count/subtype count` ratio for a fixed
/// pattern size.
void testSubtypeCount(int n) {
  var env = TestEnvironment();
  var a = env.createClass('A', isSealed: true);
  for (int i = 1; i <= n; i++) {
    env.createClass('B$i', inherits: [a]);
  }
  var t = env.createRecordType({'w': a, 'x': a, 'y': a, 'z': a});

  expectExhaustive('Subtype count $n', env, t, [
    {'w': a, 'x': a, 'y': a, 'z': a},
  ]);
}

/// Tests the how the number of pattern fields affect the number of tested
/// witness candidates.
///
/// We create the sealed class A with 5 subtypes B1 to B5:
///
///       (A)
///     /  |   \
///    B1 B2 ... B5
///
/// with the trivial matching by a record type with n fields:
///
///     method(({A a1, A a2, ..., A an} r) => switch (r) {
///       (a1: _, a2: _, ..., an: _) => 0,
///     };
///
/// which has the worst case `case count/runtime value count` ratio for a fixed
/// subtype count.
void testFieldCount(int n) {
  var env = TestEnvironment();
  var a = env.createClass('A', isSealed: true);
  for (int i = 1; i <= 5; i++) {
    env.createClass('B$i', inherits: [a]);
  }
  Map<String, StaticType> fields = {};
  for (int i = 1; i <= n; i++) {
    fields['a$i'] = a;
  }
  var t = env.createRecordType(fields);

  expectExhaustive('Field count $n', env, t, [fields]);
}

void expectExhaustive(String title, ObjectPropertyLookup objectFieldLookup,
    StaticType type, List<Map<String, Object>> cases) {
  var spaces = cases.map((c) => ty(type, c)).toList();
  profile.reset();
  print(
      isExhaustive(objectFieldLookup, Space(const Path.root(), type), spaces));
  print('--------------------------------------------------------------------');
  print(title);
  profile.log();
}
