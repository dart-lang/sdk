// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(EqualElementsInConstSetTest);
  });
}

@reflectiveTest
class EqualElementsInConstSetTest extends PubPackageResolutionTest
    with EqualElementsInConstSetTestCases {}

mixin EqualElementsInConstSetTestCases on PubPackageResolutionTest {
  test_const_entry() async {
    await resolveTestCodeWithDiagnostics(r'''
var c = const {1, 2, 1};
//             ^
// [context 1] The first element with this value.
//                   ^
// [diag.equalElementsInConstSet][context 1] Two elements in a constant set literal can't be equal.
''');
  }

  test_const_entry_extensionType_typeValue() async {
    await resolveTestCodeWithDiagnostics(r'''
const x = {int, E};
//         ^^^
// [context 1] The first element with this value.
//              ^
// [diag.equalElementsInConstSet][context 1] Two elements in a constant set literal can't be equal.
extension type E(int it) {}
''');
  }

  test_const_ifElement_thenElseFalse() async {
    await resolveTestCodeWithDiagnostics(r'''
var c = const {1, if (1 < 0) 2 else 1};
//             ^
// [context 1] The first element with this value.
//                                  ^
// [diag.equalElementsInConstSet][context 1] Two elements in a constant set literal can't be equal.
''');
  }

  test_const_ifElement_thenElseFalse_onlyElse() async {
    await resolveTestCodeWithDiagnostics(r'''
var c = const {if (0 < 1) 1 else 1};
''');
  }

  test_const_ifElement_thenElseTrue() async {
    await resolveTestCodeWithDiagnostics(r'''
var c = const {1, if (0 < 1) 2 else 1};
''');
  }

  test_const_ifElement_thenElseTrue_onlyThen() async {
    await resolveTestCodeWithDiagnostics(r'''
var c = const {if (0 < 1) 1 else 1};
''');
  }

  test_const_ifElement_thenFalse() async {
    await resolveTestCodeWithDiagnostics(r'''
var c = const {2, if (1 < 0) 2};
''');
  }

  test_const_ifElement_thenTrue() async {
    await resolveTestCodeWithDiagnostics(r'''
var c = const {1, if (0 < 1) 1};
//             ^
// [context 1] The first element with this value.
//                           ^
// [diag.equalElementsInConstSet][context 1] Two elements in a constant set literal can't be equal.
''');
  }

  test_const_instanceCreation_equalTypeArgs() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  const A();
}

var c = const {const A<int>(), const A<int>()};
//             ^^^^^^^^^^^^^^
// [context 1] The first element with this value.
//                             ^^^^^^^^^^^^^^
// [diag.equalElementsInConstSet][context 1] Two elements in a constant set literal can't be equal.
''');
  }

  test_const_instanceCreation_notEqualTypeArgs() async {
    // No error because A<int> and A<num> are different types.
    await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  const A();
}

var c = const {const A<int>(), const A<num>()};
''');
  }

  test_const_list_hasEqual() async {
    await resolveTestCodeWithDiagnostics(r'''
const x = {[0], [0]};
//         ^^^
// [context 1] The first element with this value.
//              ^^^
// [diag.equalElementsInConstSet][context 1] Two elements in a constant set literal can't be equal.
''');
  }

  test_const_list_noEqual() async {
    await resolveTestCodeWithDiagnostics(r'''
const x = {[0], [1]};
''');
  }

  test_const_record_hasEqual() async {
    await resolveTestCodeWithDiagnostics(r'''
const x = {(0, 1), (0, 1)};
//         ^^^^^^
// [context 1] The first element with this value.
//                 ^^^^^^
// [diag.equalElementsInConstSet][context 1] Two elements in a constant set literal can't be equal.
''');
  }

  test_const_record_noEqual() async {
    await resolveTestCodeWithDiagnostics(r'''
const x = {(0, 1), (0, 2)};
''');
  }

  test_const_spread__noDuplicate() async {
    await resolveTestCodeWithDiagnostics(r'''
var c = const {1, ...{2}};
''');
  }

  test_const_spread_hasDuplicate() async {
    await resolveTestCodeWithDiagnostics(r'''
var c = const {1, ...{1}};
//             ^
// [context 1] The first element with this value.
//                   ^^^
// [diag.equalElementsInConstSet][context 1] Two elements in a constant set literal can't be equal.
''');
  }

  test_nonConst_entry() async {
    // No error, but there is a hint.
    await resolveTestCodeWithDiagnostics(r'''
var c = {1, 2, 1};
//             ^
// [diag.equalElementsInSet] Two elements in a set literal shouldn't be equal.
''');
  }
}
