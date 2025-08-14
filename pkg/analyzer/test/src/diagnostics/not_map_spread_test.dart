// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NotMapSpreadTest);
    defineReflectiveTests(NotMapSpreadWithStrictCastsTest);
  });
}

@reflectiveTest
class NotMapSpreadTest extends PubPackageResolutionTest {
  test_map() async {
    await assertNoErrorsInCode('''
var a = {0: 0};
var v = <int, int>{...a};
''');
  }

  test_map_null() async {
    await assertNoErrorsInCode('''
var v = <int, int>{...?null};
''');
  }

  test_map_typeParameter_bound_map() async {
    await assertNoErrorsInCode('''
void f<T extends Map<int, String>>(T a) {
  var v = <int, String>{...a};
  v;
}
''');
  }

  test_map_typeParameter_bound_mapQuestion() async {
    await assertNoErrorsInCode('''
void f<T extends Map<int, String>?>(T a) {
  var v = <int, String>{...?a};
  v;
}
''');
  }

  test_notMap_direct() async {
    await assertErrorsInCode(
      '''
var a = 0;
var v = <int, int>{...a};
''',
      [error(CompileTimeErrorCode.notMapSpread, 33, 1)],
    );
  }

  test_notMap_forElement() async {
    await assertErrorsInCode(
      '''
var a = 0;
var v = <int, int>{for (var i in []) ...a};
''',
      [
        error(WarningCode.unusedLocalVariable, 39, 1),
        error(CompileTimeErrorCode.notMapSpread, 51, 1),
      ],
    );
  }

  test_notMap_ifElement_else() async {
    await assertErrorsInCode(
      '''
var a = 0;
var v = <int, int>{if (1 > 0) ...<int, int>{} else ...a};
''',
      [error(CompileTimeErrorCode.notMapSpread, 65, 1)],
    );
  }

  test_notMap_ifElement_then() async {
    await assertErrorsInCode(
      '''
var a = 0;
var v = <int, int>{if (1 > 0) ...a};
''',
      [error(CompileTimeErrorCode.notMapSpread, 44, 1)],
    );
  }

  test_notMap_typeParameter_bound() async {
    await assertErrorsInCode(
      '''
void f<T extends num>(T a) {
  var v = <int, int>{...a};
  v;
}
''',
      [error(CompileTimeErrorCode.notMapSpread, 53, 1)],
    );
  }
}

@reflectiveTest
class NotMapSpreadWithStrictCastsTest extends PubPackageResolutionTest
    with WithStrictCastsMixin {
  test_map() async {
    await assertErrorsWithStrictCasts(
      '''
void f(dynamic a) {
  <int, String>{...a};
}
''',
      [error(CompileTimeErrorCode.notMapSpread, 39, 1)],
    );
  }
}
