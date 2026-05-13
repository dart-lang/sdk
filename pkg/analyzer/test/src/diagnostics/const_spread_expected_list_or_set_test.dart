// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstSpreadExpectedListOrSetTest);
  });
}

@reflectiveTest
class ConstSpreadExpectedListOrSetTest extends PubPackageResolutionTest
    with ConstSpreadExpectedListOrSetTestCases {}

mixin ConstSpreadExpectedListOrSetTestCases on PubPackageResolutionTest {
  test_const_listInt() async {
    await resolveTestCodeWithDiagnostics(r'''
const dynamic a = 5;
var b = const <int>[...a];
//                     ^
// [diag.constSpreadExpectedListOrSet] A list or a set is expected in this spread.
''');
  }

  test_const_listInt_constVariable() async {
    await resolveTestCodeWithDiagnostics(r'''
const dynamic a = 5;
const x = <int>[...a];
//                 ^
// [diag.constSpreadExpectedListOrSet] A list or a set is expected in this spread.
''');
  }

  test_const_listList() async {
    await resolveTestCodeWithDiagnostics(r'''
const dynamic a = [5];
var b = const <int>[...a];
''');
  }

  test_const_listMap() async {
    await resolveTestCodeWithDiagnostics(r'''
const dynamic a = <int, int>{0: 1};
var b = const <int>[...a];
//                     ^
// [diag.constSpreadExpectedListOrSet] A list or a set is expected in this spread.
''');
  }

  test_const_listNull() async {
    await resolveTestCodeWithDiagnostics(r'''
const dynamic a = null;
var b = const <int>[...a];
//                     ^
// [diag.constSpreadExpectedListOrSet] A list or a set is expected in this spread.
''');
  }

  test_const_listNull_nullable() async {
    await resolveTestCodeWithDiagnostics(r'''
const dynamic a = null;
var b = const <int>[...?a];
''');
  }

  test_const_listSet() async {
    await resolveTestCodeWithDiagnostics(r'''
const dynamic a = <int>{5};
var b = const <int>[...a];
''');
  }

  test_const_setInt() async {
    await resolveTestCodeWithDiagnostics(r'''
const dynamic a = 5;
var b = const <int>{...a};
//                     ^
// [diag.constSpreadExpectedListOrSet] A list or a set is expected in this spread.
''');
  }

  test_const_setList() async {
    await resolveTestCodeWithDiagnostics(r'''
const dynamic a = <int>[5];
var b = const <int>{...a};
''');
  }

  test_const_setMap() async {
    await resolveTestCodeWithDiagnostics(r'''
const dynamic a = <int, int>{1: 2};
var b = const <int>{...a};
//                     ^
// [diag.constSpreadExpectedListOrSet] A list or a set is expected in this spread.
''');
  }

  test_const_setNull() async {
    await resolveTestCodeWithDiagnostics(r'''
const dynamic a = null;
var b = const <int>{...a};
//                     ^
// [diag.constSpreadExpectedListOrSet] A list or a set is expected in this spread.
''');
  }

  test_const_setNull_nullable() async {
    await resolveTestCodeWithDiagnostics(r'''
const dynamic a = null;
var b = const <int>{...?a};
''');
  }

  test_const_setSet() async {
    await resolveTestCodeWithDiagnostics(r'''
const dynamic a = <int>{5};
var b = const <int>{...a};
''');
  }

  test_nonConst_listInt() async {
    await resolveTestCodeWithDiagnostics(r'''
const dynamic a = 5;
var b = <int>[...a];
''');
  }

  test_nonConst_setInt() async {
    await resolveTestCodeWithDiagnostics(r'''
const dynamic a = 5;
var b = <int>{...a};
''');
  }
}
