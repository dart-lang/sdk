// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SetElementTypeNotAssignableTest);
    defineReflectiveTests(SetElementTypeNotAssignableWithStrictCastsTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class SetElementTypeNotAssignableTest extends PubPackageResolutionTest {
  test_const_ifElement_thenElseFalse_intInt() async {
    await resolveTestCodeWithDiagnostics(r'''
const dynamic a = 0;
const dynamic b = 0;
var v = const <int>{if (1 < 0) a else b};
''');
  }

  test_const_ifElement_thenElseFalse_intString() async {
    await resolveTestCodeWithDiagnostics(r'''
const dynamic a = 0;
const dynamic b = 'b';
var v = const <int>{if (1 < 0) a else b};
//                                    ^
// [diag.setElementTypeNotAssignable] The element type 'String' can't be assigned to the set type 'int'.
''');
  }

  test_const_ifElement_thenFalse_intString() async {
    await resolveTestCodeWithDiagnostics(r'''
var v = const <int>{if (1 < 0) 'a'};
//                             ^^^
// [diag.setElementTypeNotAssignable] The element type 'String' can't be assigned to the set type 'int'.
''');
  }

  test_const_ifElement_thenFalse_intString_dynamic() async {
    await resolveTestCodeWithDiagnostics(r'''
const dynamic a = 'a';
var v = const <int>{if (1 < 0) a};
''');
  }

  test_const_ifElement_thenTrue_intInt() async {
    await resolveTestCodeWithDiagnostics(r'''
const dynamic a = 0;
var v = const <int>{if (true) a};
''');
  }

  test_const_ifElement_thenTrue_intString() async {
    await resolveTestCodeWithDiagnostics(r'''
const dynamic a = 'a';
var v = const <int>{if (true) a};
//                            ^
// [diag.setElementTypeNotAssignable] The element type 'String' can't be assigned to the set type 'int'.
''');
  }

  test_const_intInt_dynamic() async {
    await resolveTestCodeWithDiagnostics(r'''
const dynamic a = 42;
var v = const <int>{a};
''');
  }

  test_const_intInt_value() async {
    await resolveTestCodeWithDiagnostics(r'''
var v = const <int>{42};
''');
  }

  test_const_intNull_dynamic() async {
    await resolveTestCodeWithDiagnostics(r'''
const a = null;
var v = const <int>{a};
//                  ^
// [diag.setElementTypeNotAssignableNullability] The element type 'Null' can't be assigned to the set type 'int'.
''');
  }

  test_const_intNull_value() async {
    await resolveTestCodeWithDiagnostics(r'''
var v = const <int>{null};
//                  ^^^^
// [diag.setElementTypeNotAssignableNullability] The element type 'Null' can't be assigned to the set type 'int'.
''');
  }

  test_const_intString_dynamic() async {
    await resolveTestCodeWithDiagnostics(r'''
const dynamic x = 'abc';
var v = const <int>{x};
//                  ^
// [diag.setElementTypeNotAssignable] The element type 'String' can't be assigned to the set type 'int'.
''');
  }

  test_const_intString_value() async {
    await resolveTestCodeWithDiagnostics(r'''
var v = const <int>{'abc'};
//                  ^^^^^
// [diag.setElementTypeNotAssignable] The element type 'String' can't be assigned to the set type 'int'.
''');
  }

  test_const_spread_intInt() async {
    await resolveTestCodeWithDiagnostics(r'''
var v = const <int>{...[0, 1]};
''');
  }

  test_const_stringQuestion_null_dynamic() async {
    await resolveTestCodeWithDiagnostics(r'''
const a = null;
var v = const <String?>{a};
''');
  }

  test_const_stringQuestion_null_value() async {
    await resolveTestCodeWithDiagnostics(r'''
var v = const <String?>{null};
''');
  }

  test_nonConst_ifElement_thenElseFalse_intDynamic() async {
    await resolveTestCodeWithDiagnostics(r'''
const dynamic a = 'a';
const dynamic b = 'b';
var v = <int>{if (1 < 0) a else b};
''');
  }

  test_nonConst_ifElement_thenElseFalse_intInt() async {
    await resolveTestCodeWithDiagnostics(r'''
const dynamic a = 0;
const dynamic b = 0;
var v = <int>{if (1 < 0) a else b};
''');
  }

  test_nonConst_ifElement_thenFalse_intString() async {
    await resolveTestCodeWithDiagnostics(r'''
var v = <int>[if (1 < 0) 'a'];
//                       ^^^
// [diag.listElementTypeNotAssignable] The element type 'String' can't be assigned to the list type 'int'.
''');
  }

  test_nonConst_ifElement_thenTrue_intDynamic() async {
    await resolveTestCodeWithDiagnostics(r'''
const dynamic a = 'a';
var v = <int>{if (true) a};
''');
  }

  test_nonConst_ifElement_thenTrue_intInt() async {
    await resolveTestCodeWithDiagnostics(r'''
const dynamic a = 0;
var v = <int>{if (true) a};
''');
  }

  test_nonConst_spread_intInt() async {
    await resolveTestCodeWithDiagnostics(r'''
var v = <int>{...[0, 1]};
''');
  }

  test_notConst_intString_dynamic() async {
    await resolveTestCodeWithDiagnostics(r'''
const dynamic x = 'abc';
var v = <int>{x};
''');
  }

  test_notConst_intString_value() async {
    await resolveTestCodeWithDiagnostics(r'''
var v = <int>{'abc'};
//            ^^^^^
// [diag.setElementTypeNotAssignable] The element type 'String' can't be assigned to the set type 'int'.
''');
  }
}

@reflectiveTest
class SetElementTypeNotAssignableWithStrictCastsTest
    extends PubPackageResolutionTest
    with WithStrictCastsMixin {
  test_ifElement_falseBranch() async {
    await assertTestCodeWithStrictCastsDiagnostics('''
void f(bool c, dynamic a) {
  <int>{if (c) 0 else a};
//                    ^
// [diag.setElementTypeNotAssignable] The element type 'dynamic' can't be assigned to the set type 'int'.
}
''');
  }

  test_ifElement_trueBranch() async {
    await assertTestCodeWithStrictCastsDiagnostics('''
void f(bool c, dynamic a) {
  <int>{if (c) a};
//             ^
// [diag.setElementTypeNotAssignable] The element type 'dynamic' can't be assigned to the set type 'int'.
}
''');
  }

  test_spread() async {
    await assertTestCodeWithStrictCastsDiagnostics('''
void f(Iterable<dynamic> a) {
  <int>{...a};
//         ^
// [diag.setElementTypeNotAssignable] The element type 'dynamic' can't be assigned to the set type 'int'.
}
''');
  }
}
