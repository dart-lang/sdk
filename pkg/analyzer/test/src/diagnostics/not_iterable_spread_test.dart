// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NotIterableSpreadTest);
    defineReflectiveTests(NotIterableSpreadWithStrictCastsTest);
  });
}

@reflectiveTest
class NotIterableSpreadTest extends PubPackageResolutionTest {
  test_iterable_interfaceTypeTypedef() async {
    await assertNoErrorsInCode('''
typedef A = List<int>;
f(A a) {
  var v = [...a];
  v;
}
''');
  }

  test_iterable_list() async {
    await assertNoErrorsInCode('''
var a = [0];
var v = [...a];
''');
  }

  test_iterable_null() async {
    await assertNoErrorsInCode('''
var v = [...?null];
''');
  }

  test_iterable_typeParameter_bound_list() async {
    await assertNoErrorsInCode('''
void f<T extends List<int>>(T a) {
  var v = [...a];
  v;
}
''');
  }

  test_iterable_typeParameter_bound_listQuestion() async {
    await assertNoErrorsInCode('''
void f<T extends List<int>?>(T a) {
  var v = [...?a];
  v;
}
''');
  }

  test_notIterable_direct() async {
    await assertErrorsInCode(
      '''
var a = 0;
var v = [...a];
''',
      [error(CompileTimeErrorCode.notIterableSpread, 23, 1)],
    );
  }

  test_notIterable_forElement() async {
    await assertErrorsInCode(
      '''
var a = 0;
var v = [for (var i in []) ...a];
''',
      [
        error(WarningCode.unusedLocalVariable, 29, 1),
        error(CompileTimeErrorCode.notIterableSpread, 41, 1),
      ],
    );
  }

  test_notIterable_ifElement_else() async {
    await assertErrorsInCode(
      '''
var a = 0;
var v = [if (1 > 0) ...[] else ...a];
''',
      [error(CompileTimeErrorCode.notIterableSpread, 45, 1)],
    );
  }

  test_notIterable_ifElement_then() async {
    await assertErrorsInCode(
      '''
var a = 0;
var v = [if (1 > 0) ...a];
''',
      [error(CompileTimeErrorCode.notIterableSpread, 34, 1)],
    );
  }

  test_notIterable_typeParameter_bound() async {
    await assertErrorsInCode(
      '''
void f<T extends num>(T a) {
  var v = [...a];
  v;
}
''',
      [error(CompileTimeErrorCode.notIterableSpread, 43, 1)],
    );
  }

  test_spread_map_in_iterable_context() async {
    await assertErrorsInCode(
      '''
List<int> f() => [...{1: 2, 3: 4}];
''',
      [error(CompileTimeErrorCode.notIterableSpread, 21, 12)],
    );
  }
}

@reflectiveTest
class NotIterableSpreadWithStrictCastsTest extends PubPackageResolutionTest
    with WithStrictCastsMixin {
  test_list() async {
    await assertErrorsWithStrictCasts(
      '''
void f(dynamic a) {
  [...a];
}
''',
      [error(CompileTimeErrorCode.notIterableSpread, 26, 1)],
    );
  }

  test_set() async {
    await assertErrorsWithStrictCasts(
      '''
void f(dynamic a) {
  <int>{...a};
}
''',
      [error(CompileTimeErrorCode.notIterableSpread, 31, 1)],
    );
  }
}
