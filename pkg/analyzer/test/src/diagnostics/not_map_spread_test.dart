// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NotMapSpreadTest);
    defineReflectiveTests(NotMapSpreadWithStrictCastsTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class NotMapSpreadTest extends PubPackageResolutionTest {
  test_map() async {
    await resolveTestCodeWithDiagnostics('''
var a = {0: 0};
var v = <int, int>{...a};
''');
  }

  test_map_null() async {
    await resolveTestCodeWithDiagnostics('''
var v = <int, int>{...?null};
''');
  }

  test_map_typeParameter_bound_map() async {
    await resolveTestCodeWithDiagnostics('''
void f<T extends Map<int, String>>(T a) {
  var v = <int, String>{...a};
  v;
}
''');
  }

  test_map_typeParameter_bound_mapQuestion() async {
    await resolveTestCodeWithDiagnostics('''
void f<T extends Map<int, String>?>(T a) {
  var v = <int, String>{...?a};
  v;
}
''');
  }

  test_notMap_direct() async {
    await resolveTestCodeWithDiagnostics('''
var a = 0;
var v = <int, int>{...a};
//                    ^
// [diag.notMapSpread] Spread elements in map literals must implement 'Map'.
''');
  }

  test_notMap_forElement() async {
    await resolveTestCodeWithDiagnostics('''
var a = 0;
var v = <int, int>{for (var i in []) ...a};
//                          ^
// [diag.unusedLocalVariable] The value of the local variable 'i' isn't used.
//                                      ^
// [diag.notMapSpread] Spread elements in map literals must implement 'Map'.
''');
  }

  test_notMap_ifElement_else() async {
    await resolveTestCodeWithDiagnostics('''
var a = 0;
var v = <int, int>{if (1 > 0) ...<int, int>{} else ...a};
//                                                    ^
// [diag.notMapSpread] Spread elements in map literals must implement 'Map'.
''');
  }

  test_notMap_ifElement_then() async {
    await resolveTestCodeWithDiagnostics('''
var a = 0;
var v = <int, int>{if (1 > 0) ...a};
//                               ^
// [diag.notMapSpread] Spread elements in map literals must implement 'Map'.
''');
  }

  test_notMap_iterable_inMapContext() async {
    await resolveTestCodeWithDiagnostics('''
Map<int, int> f() => {...[1, 2, 3, 4]};
//                       ^^^^^^^^^^^^
// [diag.notMapSpread] Spread elements in map literals must implement 'Map'.
''');
  }

  test_notMap_typeParameter_bound() async {
    await resolveTestCodeWithDiagnostics('''
void f<T extends num>(T a) {
  var v = <int, int>{...a};
//                      ^
// [diag.notMapSpread] Spread elements in map literals must implement 'Map'.
  v;
}
''');
  }
}

@reflectiveTest
class NotMapSpreadWithStrictCastsTest extends PubPackageResolutionTest
    with WithStrictCastsMixin {
  test_map() async {
    await assertTestCodeWithStrictCastsDiagnostics('''
void f(dynamic a) {
  <int, String>{...a};
//                 ^
// [diag.notMapSpread] Spread elements in map literals must implement 'Map'.
}
''');
  }
}
