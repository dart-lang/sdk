// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MapKeyTypeNotAssignableTest);
    defineReflectiveTests(MapKeyTypeNotAssignableWithStrictCastsTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class MapKeyTypeNotAssignableTest extends PubPackageResolutionTest {
  test_const_ifElement_thenElseFalse_intInt_dynamic() async {
    await resolveTestCodeWithDiagnostics('''
const dynamic a = 0;
const dynamic b = 0;
var v = const <int, bool>{if (1 < 0) a: true else b: false};
''');
  }

  test_const_ifElement_thenElseFalse_intString_dynamic() async {
    await resolveTestCodeWithDiagnostics('''
const dynamic a = 0;
const dynamic b = 'b';
var v = const <int, bool>{if (1 < 0) a: true else b: false};
//                                                ^
// [diag.mapKeyTypeNotAssignable] The element type 'String' can't be assigned to the map key type 'int'.
''');
  }

  test_const_ifElement_thenFalse_intString_dynamic() async {
    await resolveTestCodeWithDiagnostics('''
const dynamic a = 'a';
var v = const <int, bool>{if (1 < 0) a: true};
''');
  }

  test_const_ifElement_thenFalse_intString_value() async {
    await resolveTestCodeWithDiagnostics('''
var v = const <int, bool>{if (1 < 0) 'a': true};
//                                   ^^^
// [diag.mapKeyTypeNotAssignable] The element type 'String' can't be assigned to the map key type 'int'.
''');
  }

  test_const_ifElement_thenTrue_intInt_dynamic() async {
    await resolveTestCodeWithDiagnostics('''
const dynamic a = 0;
var v = const <int, bool>{if (true) a: true};
''');
  }

  test_const_ifElement_thenTrue_intString_dynamic() async {
    await resolveTestCodeWithDiagnostics('''
const dynamic a = 'a';
var v = const <int, bool>{if (true) a: true};
//                                  ^
// [diag.mapKeyTypeNotAssignable] The element type 'String' can't be assigned to the map key type 'int'.
''');
  }

  test_const_ifElement_thenTrue_notConst() async {
    await resolveTestCodeWithDiagnostics('''
final a = 0;
var v = const <int, bool>{if (1 < 2) a: true};
//                                   ^
// [diag.nonConstantMapKey] The keys in a const map literal must be constant.
''');
  }

  test_const_intInt_dynamic() async {
    await resolveTestCodeWithDiagnostics('''
const dynamic a = 0;
var v = const <int, bool>{a : true};
''');
  }

  test_const_intNull_dynamic() async {
    await resolveTestCodeWithDiagnostics('''
const dynamic a = null;
var v = const <int, bool>{a : true};
//                        ^
// [diag.mapKeyTypeNotAssignableNullability] The element type 'Null' can't be assigned to the map key type 'int'.
''');
  }

  test_const_intNull_value() async {
    await resolveTestCodeWithDiagnostics('''
var v = const <int, bool>{null : true};
//                        ^^^^
// [diag.mapKeyTypeNotAssignableNullability] The element type 'Null' can't be assigned to the map key type 'int'.
''');
  }

  test_const_intQuestion_null_dynamic() async {
    await resolveTestCodeWithDiagnostics('''
const dynamic a = null;
var v = const <int?, bool>{a : true};
''');
  }

  test_const_intQuestion_null_value() async {
    await resolveTestCodeWithDiagnostics('''
var v = const <int?, bool>{null : true};
''');
  }

  test_const_intString_dynamic() async {
    await resolveTestCodeWithDiagnostics('''
const dynamic a = 'a';
var v = const <int, bool>{a : true};
//                        ^
// [diag.mapKeyTypeNotAssignable] The element type 'String' can't be assigned to the map key type 'int'.
''');
  }

  test_const_intString_value() async {
    await resolveTestCodeWithDiagnostics('''
var v = const <int, bool>{'a' : true};
//                        ^^^
// [diag.mapKeyTypeNotAssignable] The element type 'String' can't be assigned to the map key type 'int'.
''');
  }

  test_const_spread_intInt() async {
    await resolveTestCodeWithDiagnostics('''
var v = const <int, String>{...{1: 'a'}};
''');
  }

  test_const_spread_intString_dynamic() async {
    await resolveTestCodeWithDiagnostics('''
const dynamic a = 'a';
var v = const <int, String>{...{a: 'a'}};
//                              ^
// [diag.mapKeyTypeNotAssignable] The element type 'String' can't be assigned to the map key type 'int'.
''');
  }

  test_key_type_is_assignable() async {
    await resolveTestCodeWithDiagnostics('''
var v = <String, int > {'a' : 1};
''');
  }

  test_nonConst_ifElement_thenElseFalse_intInt_dynamic() async {
    await resolveTestCodeWithDiagnostics('''
const dynamic a = 0;
const dynamic b = 0;
var v = <int, bool>{if (1 < 0) a: true else b: false};
''');
  }

  test_nonConst_ifElement_thenElseFalse_intString_dynamic() async {
    await resolveTestCodeWithDiagnostics('''
const dynamic a = 0;
const dynamic b = 'b';
var v = <int, bool>{if (1 < 0) a: true else b: false};
''');
  }

  test_nonConst_ifElement_thenFalse_intString_value() async {
    await resolveTestCodeWithDiagnostics('''
var v = <int, bool>{if (1 < 0) 'a': true};
//                             ^^^
// [diag.mapKeyTypeNotAssignable] The element type 'String' can't be assigned to the map key type 'int'.
''');
  }

  test_nonConst_ifElement_thenTrue_intInt_dynamic() async {
    await resolveTestCodeWithDiagnostics('''
const dynamic a = 0;
var v = <int, bool>{if (true) a: true};
''');
  }

  test_nonConst_ifElement_thenTrue_intString_dynamic() async {
    await resolveTestCodeWithDiagnostics('''
const dynamic a = 'a';
var v = <int, bool>{if (true) a: true};
''');
  }

  test_nonConst_intInt_dynamic() async {
    await resolveTestCodeWithDiagnostics('''
const dynamic a = 0;
var v = <int, bool>{a : true};
''');
  }

  test_nonConst_intString_dynamic() async {
    await resolveTestCodeWithDiagnostics('''
const dynamic a = 'a';
var v = <int, bool>{a : true};
''');
  }

  test_nonConst_intString_value() async {
    await resolveTestCodeWithDiagnostics('''
var v = <int, bool>{'a' : true};
//                  ^^^
// [diag.mapKeyTypeNotAssignable] The element type 'String' can't be assigned to the map key type 'int'.
''');
  }

  test_nonConst_spread_intInt() async {
    await resolveTestCodeWithDiagnostics('''
var v = <int, String>{...{1: 'a'}};
''');
  }

  test_nonConst_spread_intString() async {
    await resolveTestCodeWithDiagnostics('''
var v = <int, String>{...{'a': 'a'}};
//                        ^^^
// [diag.mapKeyTypeNotAssignable] The element type 'String' can't be assigned to the map key type 'int'.
''');
  }

  test_nonConst_spread_intString_dynamic() async {
    await resolveTestCodeWithDiagnostics('''
dynamic a = 'a';
var v = <int, String>{...{a: 'a'}};
''');
  }
}

@reflectiveTest
class MapKeyTypeNotAssignableWithStrictCastsTest
    extends PubPackageResolutionTest
    with WithStrictCastsMixin {
  test_ifElement_falseBranch() async {
    await assertTestCodeWithStrictCastsDiagnostics('''
void f(bool c, dynamic a) {
  <int, int>{if (c) 0: 0 else a: 0};
//                            ^
// [diag.mapKeyTypeNotAssignable] The element type 'dynamic' can't be assigned to the map key type 'int'.
}
''');
  }

  test_ifElement_trueBranch() async {
    await assertTestCodeWithStrictCastsDiagnostics('''
void f(bool c, dynamic a) {
  <int, int>{if (c) a: 0 };
//                  ^
// [diag.mapKeyTypeNotAssignable] The element type 'dynamic' can't be assigned to the map key type 'int'.
}
''');
  }

  test_spread() async {
    await assertTestCodeWithStrictCastsDiagnostics('''
void f(Map<dynamic, int> a) {
  <int, int>{...a};
//              ^
// [diag.mapKeyTypeNotAssignable] The element type 'dynamic' can't be assigned to the map key type 'int'.
}
''');
  }
}
