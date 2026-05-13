// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AmbiguousSetOrMapLiteralBothTest);
    defineReflectiveTests(AmbiguousSetOrMapLiteralEitherTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class AmbiguousSetOrMapLiteralBothTest extends PubPackageResolutionTest {
  test_map() async {
    await resolveTestCodeWithDiagnostics(r'''
f(Map<int, int> map) {
  return {...map};
}
''');
  }

  test_map_dynamic() async {
    await resolveTestCodeWithDiagnostics(r'''
f(Map map) {
  return {...map};
}
''');
  }

  test_map_keyNonNullable_valueNullable() async {
    await resolveTestCodeWithDiagnostics(r'''
f(Map<int, int?> map) {
  return {...map};
}
''');
  }

  test_map_keyNullable_valueNonNullable() async {
    await resolveTestCodeWithDiagnostics(r'''
f(Map<int?, int> map) {
  return {...map};
}
''');
  }

  test_map_keyNullable_valueNullable() async {
    await resolveTestCodeWithDiagnostics(r'''
f(Map<int?, int?> map) {
  return {...map};
}
''');
  }

  test_set() async {
    await resolveTestCodeWithDiagnostics(r'''
f(Set<int> set) {
  return {...set};
}
''');
  }

  test_set_dynamic() async {
    await resolveTestCodeWithDiagnostics(r'''
f(Set set) {
  return {...set};
}
''');
  }

  test_set_elementNullable() async {
    await resolveTestCodeWithDiagnostics(r'''
f(Set<int?> set) {
  return {...set};
}
''');
  }

  test_setAndMap() async {
    await resolveTestCodeWithDiagnostics(r'''
f(Map<int, int> map, Set<int> set) {
  return {...set, ...map};
//       ^^^^^^^^^^^^^^^^
// [diag.ambiguousSetOrMapLiteralBoth] The literal can't be either a map or a set because it contains at least one literal map entry or a spread operator spreading a 'Map', and at least one element which is neither of these.
}
''');
  }

  test_setAndMap_nullable() async {
    await resolveTestCodeWithDiagnostics(r'''
f(Map<int?, int> map, Set<int?> set) {
  return {...set, ...map};
//       ^^^^^^^^^^^^^^^^
// [diag.ambiguousSetOrMapLiteralBoth] The literal can't be either a map or a set because it contains at least one literal map entry or a spread operator spreading a 'Map', and at least one element which is neither of these.
}
''');
  }
}

@reflectiveTest
class AmbiguousSetOrMapLiteralEitherTest extends PubPackageResolutionTest {
  test_invalidPrefixOperator() async {
    // Guard against an exception being thrown.
    await resolveTestCodeWithDiagnostics(r'''
union(a, b) => !{...a, ...b};
//              ^^^^^^^^^^^^
// [diag.ambiguousSetOrMapLiteralEither] This literal must be either a map or a set, but the elements don't have enough information for type inference to work.
''');
  }

  test_setAndMap() async {
    await resolveTestCodeWithDiagnostics(r'''
var map;
var set;
var c = {...set, ...map};
//      ^^^^^^^^^^^^^^^^
// [diag.ambiguousSetOrMapLiteralEither] This literal must be either a map or a set, but the elements don't have enough information for type inference to work.
''');
  }
}
