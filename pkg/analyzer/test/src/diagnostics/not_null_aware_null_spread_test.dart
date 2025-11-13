// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NotNullAwareNullSpreadTest);
  });
}

@reflectiveTest
class NotNullAwareNullSpreadTest extends PubPackageResolutionTest {
  test_listLiteral_notNullAware_nullLiteral() async {
    await assertErrorsInCode(
      '''
var v = [...null];
''',
      [
        error(diag.invalidUseOfNullValue, 12, 4),
        error(diag.notNullAwareNullSpread, 12, 4),
      ],
    );
  }

  test_listLiteral_notNullAware_nullTyped() async {
    await assertErrorsInCode(
      '''
Null a = null;
var v = [...a];
''',
      [
        error(diag.invalidUseOfNullValue, 27, 1),
        error(diag.notNullAwareNullSpread, 27, 1),
      ],
    );
  }

  test_listLiteral_nullAware_nullLiteral() async {
    await assertNoErrorsInCode('''
var v = [...?null];
''');
  }

  test_listLiteral_nullAware_nullTyped() async {
    await assertNoErrorsInCode('''
Null a = null;
var v = [...?a];
''');
  }

  test_mapLiteral_notNullAware_nullLiteral() async {
    await assertErrorsInCode(
      '''
var v = <int, int>{...null};
''',
      [
        error(diag.invalidUseOfNullValue, 22, 4),
        error(diag.notNullAwareNullSpread, 22, 4),
      ],
    );
  }

  test_mapLiteral_notNullAware_nullType() async {
    await assertErrorsInCode(
      '''
Null a = null;
var v = <int, int>{...a};
''',
      [
        error(diag.invalidUseOfNullValue, 37, 1),
        error(diag.notNullAwareNullSpread, 37, 1),
      ],
    );
  }

  test_mapLiteral_nullAware_nullLiteral() async {
    await assertNoErrorsInCode('''
var v = <int, int>{...?null};
''');
  }

  test_mapLiteral_nullAware_nullType() async {
    await assertNoErrorsInCode('''
Null a = null;
var v = <int, int>{...?a};
''');
  }

  test_setLiteral_notNullAware_nullLiteral() async {
    await assertErrorsInCode(
      '''
var v = <int>{...null};
''',
      [
        error(diag.invalidUseOfNullValue, 17, 4),
        error(diag.notNullAwareNullSpread, 17, 4),
      ],
    );
  }

  test_setLiteral_notNullAware_nullTyped() async {
    await assertErrorsInCode(
      '''
Null a = null;
var v = <int>{...a};
''',
      [
        error(diag.invalidUseOfNullValue, 32, 1),
        error(diag.notNullAwareNullSpread, 32, 1),
      ],
    );
  }

  test_setLiteral_nullAware_nullLiteral() async {
    await assertNoErrorsInCode('''
var v = <int>{...?null};
''');
  }

  test_setLiteral_nullAware_nullTyped() async {
    await assertNoErrorsInCode('''
Null a = null;
var v = <int>{...?a};
''');
  }
}
