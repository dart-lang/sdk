// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NotIterableSpreadTest);
    defineReflectiveTests(NotIterableSpreadWithStrictCastsTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class NotIterableSpreadTest extends PubPackageResolutionTest {
  test_iterable_interfaceTypeTypedef() async {
    await resolveTestCodeWithDiagnostics('''
typedef A = List<int>;
f(A a) {
  var v = [...a];
  v;
}
''');
  }

  test_iterable_list() async {
    await resolveTestCodeWithDiagnostics('''
var a = [0];
var v = [...a];
''');
  }

  test_iterable_null() async {
    await resolveTestCodeWithDiagnostics('''
var v = [...?null];
''');
  }

  test_iterable_typeParameter_bound_list() async {
    await resolveTestCodeWithDiagnostics('''
void f<T extends List<int>>(T a) {
  var v = [...a];
  v;
}
''');
  }

  test_iterable_typeParameter_bound_listQuestion() async {
    await resolveTestCodeWithDiagnostics('''
void f<T extends List<int>?>(T a) {
  var v = [...?a];
  v;
}
''');
  }

  test_notIterable_direct() async {
    await resolveTestCodeWithDiagnostics('''
var a = 0;
var v = [...a];
//          ^
// [diag.notIterableSpread] Spread elements in list or set literals must implement 'Iterable'.
''');
  }

  test_notIterable_forElement() async {
    await resolveTestCodeWithDiagnostics('''
var a = 0;
var v = [for (var i in []) ...a];
//                ^
// [diag.unusedLocalVariable] The value of the local variable 'i' isn't used.
//                            ^
// [diag.notIterableSpread] Spread elements in list or set literals must implement 'Iterable'.
''');
  }

  test_notIterable_ifElement_else() async {
    await resolveTestCodeWithDiagnostics('''
var a = 0;
var v = [if (1 > 0) ...[] else ...a];
//                                ^
// [diag.notIterableSpread] Spread elements in list or set literals must implement 'Iterable'.
''');
  }

  test_notIterable_ifElement_then() async {
    await resolveTestCodeWithDiagnostics('''
var a = 0;
var v = [if (1 > 0) ...a];
//                     ^
// [diag.notIterableSpread] Spread elements in list or set literals must implement 'Iterable'.
''');
  }

  test_notIterable_typeParameter_bound() async {
    await resolveTestCodeWithDiagnostics('''
void f<T extends num>(T a) {
  var v = [...a];
//            ^
// [diag.notIterableSpread] Spread elements in list or set literals must implement 'Iterable'.
  v;
}
''');
  }

  test_spread_map_in_iterable_context() async {
    await resolveTestCodeWithDiagnostics('''
List<int> f() => [...{1: 2, 3: 4}];
//                   ^^^^^^^^^^^^
// [diag.notIterableSpread] Spread elements in list or set literals must implement 'Iterable'.
''');
  }
}

@reflectiveTest
class NotIterableSpreadWithStrictCastsTest extends PubPackageResolutionTest
    with WithStrictCastsMixin {
  test_list() async {
    await assertTestCodeWithStrictCastsDiagnostics('''
void f(dynamic a) {
  [...a];
//    ^
// [diag.notIterableSpread] Spread elements in list or set literals must implement 'Iterable'.
}
''');
  }

  test_set() async {
    await assertTestCodeWithStrictCastsDiagnostics('''
void f(dynamic a) {
  <int>{...a};
//         ^
// [diag.notIterableSpread] Spread elements in list or set literals must implement 'Iterable'.
}
''');
  }
}
