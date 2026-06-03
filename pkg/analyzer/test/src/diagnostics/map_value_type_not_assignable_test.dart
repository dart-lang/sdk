// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MapValueTypeNotAssignableTest);
    defineReflectiveTests(MapValueTypeNotAssignableWithStrictCastsTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class MapValueTypeNotAssignableTest extends PubPackageResolutionTest {
  test_const_ifElement_thenElseFalse_intInt_dynamic() async {
    await resolveTestCodeWithDiagnostics('''
const dynamic a = 0;
const dynamic b = 0;
var v = const <bool, int>{if (1 < 0) true: a else false: b};
''');
  }

  test_const_ifElement_thenElseFalse_intString_dynamic() async {
    await resolveTestCodeWithDiagnostics('''
const dynamic a = 0;
const dynamic b = 'b';
var v = const <bool, int>{if (1 < 0) true: a else false: b};
//                                                       ^
// [diag.mapValueTypeNotAssignable] The element type 'String' can't be assigned to the map value type 'int'.
''');
  }

  test_const_ifElement_thenFalse_intString_dynamic() async {
    await resolveTestCodeWithDiagnostics('''
const dynamic a = 'a';
var v = const <bool, int>{if (1 < 0) true: a};
''');
  }

  test_const_ifElement_thenFalse_intString_value() async {
    await resolveTestCodeWithDiagnostics('''
var v = const <bool, int>{if (1 < 0) true: 'a'};
//                                         ^^^
// [diag.mapValueTypeNotAssignable] The element type 'String' can't be assigned to the map value type 'int'.
''');
  }

  test_const_ifElement_thenTrue_intInt_dynamic() async {
    await resolveTestCodeWithDiagnostics('''
const dynamic a = 0;
var v = const <bool, int>{if (true) true: a};
''');
  }

  test_const_ifElement_thenTrue_intString_dynamic() async {
    await resolveTestCodeWithDiagnostics('''
const dynamic a = 'a';
var v = const <bool, int>{if (true) true: a};
//                                        ^
// [diag.mapValueTypeNotAssignable] The element type 'String' can't be assigned to the map value type 'int'.
''');
  }

  test_const_ifElement_thenTrue_notConst() async {
    await resolveTestCodeWithDiagnostics('''
final a = 0;
var v = const <bool, int>{if (1 < 2) true: a};
//                                         ^
// [diag.nonConstantMapValue] The values in a const map literal must be constant.
''');
  }

  test_const_intInt_dynamic() async {
    await resolveTestCodeWithDiagnostics('''
const dynamic a = 0;
var v = const <bool, int>{true: a};
''');
  }

  test_const_intNull_dynamic() async {
    await resolveTestCodeWithDiagnostics('''
const dynamic a = null;
var v = const <bool, int>{true: a};
//                              ^
// [diag.mapValueTypeNotAssignableNullability] The element type 'Null' can't be assigned to the map value type 'int'.
''');
  }

  test_const_intNull_value() async {
    await resolveTestCodeWithDiagnostics('''
var v = const <bool, int>{true: null};
//                              ^^^^
// [diag.mapValueTypeNotAssignableNullability] The element type 'Null' can't be assigned to the map value type 'int'.
''');
  }

  test_const_intQuestion_null_dynamic() async {
    await resolveTestCodeWithDiagnostics('''
const dynamic a = null;
var v = const <bool, int?>{true: a};
''');
  }

  test_const_intQuestion_null_value() async {
    await resolveTestCodeWithDiagnostics('''
var v = const <bool, int?>{true: null};
''');
  }

  test_const_intString_dynamic() async {
    await resolveTestCodeWithDiagnostics('''
const dynamic a = 'a';
var v = const <bool, int>{true: a};
//                              ^
// [diag.mapValueTypeNotAssignable] The element type 'String' can't be assigned to the map value type 'int'.
''');
  }

  test_const_intString_value() async {
    await resolveTestCodeWithDiagnostics('''
var v = const <bool, int>{true: 'a'};
//                              ^^^
// [diag.mapValueTypeNotAssignable] The element type 'String' can't be assigned to the map value type 'int'.
''');
  }

  test_const_spread_intInt() async {
    await resolveTestCodeWithDiagnostics('''
var v = const <bool, int>{...{true: 1}};
''');
  }

  test_const_spread_intString_dynamic() async {
    await resolveTestCodeWithDiagnostics('''
const dynamic a = 'a';
var v = const <bool, int>{...{true: a}};
//                                  ^
// [diag.mapValueTypeNotAssignable] The element type 'String' can't be assigned to the map value type 'int'.
''');
  }

  test_nonConst_ifElement_thenElseFalse_intInt_dynamic() async {
    await resolveTestCodeWithDiagnostics('''
const dynamic a = 0;
const dynamic b = 0;
var v = <bool, int>{if (1 < 0) true: a else false: b};
''');
  }

  test_nonConst_ifElement_thenElseFalse_intString_dynamic() async {
    await resolveTestCodeWithDiagnostics('''
const dynamic a = 0;
const dynamic b = 'b';
var v = <bool, int>{if (1 < 0) true: a else false: b};
''');
  }

  test_nonConst_ifElement_thenFalse_intString_value() async {
    await resolveTestCodeWithDiagnostics('''
var v = <bool, int>{if (1 < 0) true: 'a'};
//                                   ^^^
// [diag.mapValueTypeNotAssignable] The element type 'String' can't be assigned to the map value type 'int'.
''');
  }

  test_nonConst_ifElement_thenTrue_intInt_dynamic() async {
    await resolveTestCodeWithDiagnostics('''
const dynamic a = 0;
var v = <bool, int>{if (true) true: a};
''');
  }

  test_nonConst_ifElement_thenTrue_intString_dynamic() async {
    await resolveTestCodeWithDiagnostics('''
const dynamic a = 'a';
var v = <bool, int>{if (true) true: a};
''');
  }

  test_nonConst_intInt_dynamic() async {
    await resolveTestCodeWithDiagnostics('''
const dynamic a = 0;
var v = <bool, int>{true: a};
''');
  }

  test_nonConst_intString_dynamic() async {
    await resolveTestCodeWithDiagnostics('''
const dynamic a = 'a';
var v = <bool, int>{true: a};
''');
  }

  test_nonConst_intString_value() async {
    await resolveTestCodeWithDiagnostics('''
var v = <bool, int>{true: 'a'};
//                        ^^^
// [diag.mapValueTypeNotAssignable] The element type 'String' can't be assigned to the map value type 'int'.
''');
  }

  test_nonConst_spread_intInt() async {
    await resolveTestCodeWithDiagnostics('''
var v = <bool, int>{...{true: 1}};
''');
  }

  test_nonConst_spread_intString() async {
    await resolveTestCodeWithDiagnostics('''
var v = <bool, int>{...{true: 'a'}};
//                            ^^^
// [diag.mapValueTypeNotAssignable] The element type 'String' can't be assigned to the map value type 'int'.
''');
  }

  test_nonConst_spread_intString_dynamic() async {
    await resolveTestCodeWithDiagnostics('''
const dynamic a = 'a';
var v = <bool, int>{...{true: a}};
''');
  }
}

@reflectiveTest
class MapValueTypeNotAssignableWithStrictCastsTest
    extends PubPackageResolutionTest
    with WithStrictCastsMixin {
  test_ifElement_falseBranch() async {
    await assertTestCodeWithStrictCastsDiagnostics('''
void f(bool c, dynamic a) {
  <int, int>{if (c) 0: 0 else 0: a};
//                               ^
// [diag.mapValueTypeNotAssignable] The element type 'dynamic' can't be assigned to the map value type 'int'.
}
''');
  }

  test_ifElement_trueBranch() async {
    await assertTestCodeWithStrictCastsDiagnostics('''
void f(bool c, dynamic a) {
  <int, int>{if (c) 0: a};
//                     ^
// [diag.mapValueTypeNotAssignable] The element type 'dynamic' can't be assigned to the map value type 'int'.
}
''');
  }

  test_spread() async {
    await assertTestCodeWithStrictCastsDiagnostics('''
void f(Map<int, dynamic> a) {
  <int, int>{...a};
//              ^
// [diag.mapValueTypeNotAssignable] The element type 'dynamic' can't be assigned to the map value type 'int'.
}
''');
  }
}
