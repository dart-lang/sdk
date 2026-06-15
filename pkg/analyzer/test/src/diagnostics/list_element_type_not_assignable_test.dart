// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ListElementTypeNotAssignableTest);
    defineReflectiveTests(ListElementTypeNotAssignableWithStrictCastsTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class ListElementTypeNotAssignableTest extends PubPackageResolutionTest {
  test_const_ifElement_thenElseFalse_intInt() async {
    await resolveTestCodeWithDiagnostics('''
const dynamic a = 0;
const dynamic b = 0;
var v = const <int>[if (1 < 0) a else b];
''');
  }

  test_const_ifElement_thenElseFalse_intString() async {
    await resolveTestCodeWithDiagnostics('''
const dynamic a = 0;
const dynamic b = 'b';
var v = const <int>[if (1 < 0) a else b];
//                                    ^
// [diag.listElementTypeNotAssignable] The element type 'String' can't be assigned to the list type 'int'.
''');
  }

  test_const_ifElement_thenFalse_intString() async {
    await resolveTestCodeWithDiagnostics('''
var v = const <int>[if (1 < 0) 'a'];
//                             ^^^
// [diag.listElementTypeNotAssignable] The element type 'String' can't be assigned to the list type 'int'.
''');
  }

  test_const_ifElement_thenFalse_intString_dynamic() async {
    await resolveTestCodeWithDiagnostics('''
const dynamic a = 'a';
var v = const <int>[if (1 < 0) a];
''');
  }

  test_const_ifElement_thenTrue_intInt() async {
    await resolveTestCodeWithDiagnostics('''
const dynamic a = 0;
var v = const <int>[if (true) a];
''');
  }

  test_const_ifElement_thenTrue_intString() async {
    await resolveTestCodeWithDiagnostics('''
const dynamic a = 'a';
var v = const <int>[if (true) a];
//                            ^
// [diag.listElementTypeNotAssignable] The element type 'String' can't be assigned to the list type 'int'.
''');
  }

  test_const_intInt() async {
    await resolveTestCodeWithDiagnostics(r'''
var v1 = <int> [42];
var v2 = const <int> [42];
''');
  }

  test_const_intNull_dynamic() async {
    await resolveTestCodeWithDiagnostics('''
const a = null;
var v = const <int>[a];
//                  ^
// [diag.listElementTypeNotAssignableNullability] The element type 'Null' can't be assigned to the list type 'int'.
''');
  }

  test_const_intNull_value() async {
    await resolveTestCodeWithDiagnostics('''
var v = const <int>[null];
//                  ^^^^
// [diag.listElementTypeNotAssignableNullability] The element type 'Null' can't be assigned to the list type 'int'.
''');
  }

  test_const_spread_intInt() async {
    await resolveTestCodeWithDiagnostics('''
var v = const <int>[...[0, 1]];
''');
  }

  test_const_stringInt() async {
    await resolveTestCodeWithDiagnostics('''
var v = const <String>[42];
//                     ^^
// [diag.listElementTypeNotAssignable] The element type 'int' can't be assigned to the list type 'String'.
''');
  }

  test_const_stringInt_dynamic() async {
    await resolveTestCodeWithDiagnostics('''
const dynamic x = 42;
var v = const <String>[x];
//                     ^
// [diag.listElementTypeNotAssignable] The element type 'int' can't be assigned to the list type 'String'.
''');
  }

  test_const_stringQuestion_null_value() async {
    await resolveTestCodeWithDiagnostics('''
var v = const <String?>[null];
''');
  }

  test_const_voidInt() async {
    await resolveTestCodeWithDiagnostics('''
var v = const <void>[42];
''');
  }

  test_nonConst_genericFunction_genericContext() async {
    await resolveTestCodeWithDiagnostics('''
List<U Function<U>(U)> foo(T Function<T>(T a) f) {
  return [f];
}
''');
  }

  test_nonConst_genericFunction_genericContext_nonAssignable() async {
    await resolveTestCodeWithDiagnostics('''
List<U Function<U>(U, int)> foo(T Function<T>(T a) f) {
  return [f];
//        ^
// [diag.listElementTypeNotAssignable] The element type 'T Function<T>(T)' can't be assigned to the list type 'U Function<U>(U, int)'.
}
''');
  }

  test_nonConst_genericFunction_nonGenericContext() async {
    await resolveTestCodeWithDiagnostics('''
List<int Function(int)> foo(T Function<T>(T a) f) {
  return [f];
}
''');
  }

  test_nonConst_genericFunction_nonGenericContext_nonAssignable() async {
    await resolveTestCodeWithDiagnostics('''
List<int Function(int, int)> foo(T Function<T>(T a) f) {
  return [f];
//        ^
// [diag.listElementTypeNotAssignable] The element type 'dynamic Function(dynamic)' can't be assigned to the list type 'int Function(int, int)'.
}
''');
  }

  test_nonConst_ifElement_thenElseFalse_intDynamic() async {
    await resolveTestCodeWithDiagnostics('''
const dynamic a = 'a';
const dynamic b = 'b';
var v = <int>[if (1 < 0) a else b];
''');
  }

  test_nonConst_ifElement_thenElseFalse_intInt() async {
    await resolveTestCodeWithDiagnostics('''
const dynamic a = 0;
const dynamic b = 0;
var v = <int>[if (1 < 0) a else b];
''');
  }

  test_nonConst_ifElement_thenFalse_intString() async {
    await resolveTestCodeWithDiagnostics('''
var v = <int>[if (1 < 0) 'a'];
//                       ^^^
// [diag.listElementTypeNotAssignable] The element type 'String' can't be assigned to the list type 'int'.
''');
  }

  test_nonConst_ifElement_thenTrue_intDynamic() async {
    await resolveTestCodeWithDiagnostics('''
const dynamic a = 'a';
var v = <int>[if (true) a];
''');
  }

  test_nonConst_ifElement_thenTrue_intInt() async {
    await resolveTestCodeWithDiagnostics('''
const dynamic a = 0;
var v = <int>[if (true) a];
''');
  }

  test_nonConst_spread_intInt() async {
    await resolveTestCodeWithDiagnostics('''
var v = <int>[...[0, 1]];
''');
  }

  test_nonConst_stringInt() async {
    await resolveTestCodeWithDiagnostics('''
var v = <String>[42];
//               ^^
// [diag.listElementTypeNotAssignable] The element type 'int' can't be assigned to the list type 'String'.
''');
  }

  test_nonConst_stringInt_dynamic() async {
    await resolveTestCodeWithDiagnostics('''
const dynamic x = 42;
var v = <String>[x];
''');
  }

  test_nonConst_voidInt() async {
    await resolveTestCodeWithDiagnostics('''
var v = <void>[42];
''');
  }
}

@reflectiveTest
class ListElementTypeNotAssignableWithStrictCastsTest
    extends PubPackageResolutionTest
    with WithStrictCastsMixin {
  test_ifElement_falseBranch() async {
    await assertTestCodeWithStrictCastsDiagnostics('''
void f(bool c, dynamic a) {
  <int>[if (c) 0 else a];
//                    ^
// [diag.listElementTypeNotAssignable] The element type 'dynamic' can't be assigned to the list type 'int'.
}
''');
  }

  test_ifElement_trueBranch() async {
    await assertTestCodeWithStrictCastsDiagnostics('''
void f(bool c, dynamic a) {
  <int>[if (c) a];
//             ^
// [diag.listElementTypeNotAssignable] The element type 'dynamic' can't be assigned to the list type 'int'.
}
''');
  }

  test_spread() async {
    await assertTestCodeWithStrictCastsDiagnostics('''
void f(Iterable<dynamic> a) {
  <int>[...a];
//         ^
// [diag.listElementTypeNotAssignable] The element type 'dynamic' can't be assigned to the list type 'int'.
}
''');
  }
}
