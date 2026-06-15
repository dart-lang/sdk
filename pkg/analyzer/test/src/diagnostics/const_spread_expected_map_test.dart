// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstSpreadExpectedMapTest);
  });
}

@reflectiveTest
class ConstSpreadExpectedMapTest extends PubPackageResolutionTest
    with ConstSpreadExpectedMapTestCases {}

mixin ConstSpreadExpectedMapTestCases on PubPackageResolutionTest {
  test_const_mapInt() async {
    await resolveTestCodeWithDiagnostics(r'''
const dynamic a = 5;
var b = const <int, int>{...a};
//                          ^
// [diag.constSpreadExpectedMap] A map is expected in this spread.
''');
  }

  test_const_mapList() async {
    await resolveTestCodeWithDiagnostics(r'''
const dynamic a = <int>[5];
var b = const <int, int>{...a};
//                          ^
// [diag.constSpreadExpectedMap] A map is expected in this spread.
''');
  }

  test_const_mapMap() async {
    await resolveTestCodeWithDiagnostics(r'''
const dynamic a = <int, int>{1: 2};
var b = <int, int>{...a};
''');
  }

  test_const_mapNull() async {
    await resolveTestCodeWithDiagnostics(r'''
const dynamic a = null;
var b = const <int, int>{...a};
//                          ^
// [diag.constSpreadExpectedMap] A map is expected in this spread.
''');
  }

  test_const_mapNull_nullable() async {
    await resolveTestCodeWithDiagnostics(r'''
const dynamic a = null;
var b = <int, int>{...?a};
''');
  }

  test_const_mapSet() async {
    await resolveTestCodeWithDiagnostics(r'''
const dynamic a = <int>{5};
var b = const <int, int>{...a};
//                          ^
// [diag.constSpreadExpectedMap] A map is expected in this spread.
''');
  }

  test_nonConst_mapInt() async {
    await resolveTestCodeWithDiagnostics(r'''
const dynamic a = 5;
var b = <int, int>{...a};
''');
  }

  test_nonConst_mapMap() async {
    await resolveTestCodeWithDiagnostics(r'''
const dynamic a = {1: 2};
var b = <int, int>{...a};
''');
  }
}
